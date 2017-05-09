# Nagios moduulin luonti

Tarkoituksena on asentaa LAMP, NAGIOS ja luoda niille ainakin perusmääritykset.

Harjoituksen vaihe 1 tehtiin Haaga-Helia Pasilan luokassa 5004 PC 15. 
Käyttöjärjestelmänä toimi Xubuntu 16.04.2, joka pyöri usb-tikulta live-tilassa.

Kotona käytän Docker for Windows v 17.03.1-ce työkalua, jolla olen luonut puppetmaster ja puppetagent kontteja (container).
Eli käytännössä sama kuin käyttäisi vagranttia, mutta Dockerin avulla voi tehdä paljon muutakin.

Hyvä lopputulos olisi se, että nagioksen sivulle pääsisi kiinni ja siellä olisi
ainakin 1 kone, jota valvotaan, että kone on päällä. Katsotaan kuinka pitkälle pääsen.
Tähän käytetään nagioksen ping toimintoa.

## Esivalmisteluita

Loin ensin Dockerfile tiedoston, jonne tein perusmääritykset nagios konetta varten. Dockerin avullahan voisi toteuttaa saman kuin mitä nyt puppetilla olemme tekemässä, eli luomassa koneen, jossa on halutut toiminnot mahdollisimman automatisoituna.

(Docker docs 2017.)

Tiedoston sisältö

	# Building from ubuntu 16.04-sshd
	FROM ubuntu-sshd:16.04

	# Installing prerequisites for nagios
	RUN apt-get install -y wget build-essential apache2 php apache2-mod-php7.0 php-gd libgd-dev unzip tzdata

	# Change timezone to Europe/Helsinki
	RUN cp /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

	# Downloading nagios core and required plugins
	RUN cd /tmp \
	&& wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.3.1.tar.gz#_ga=2.29079733.863927744.1494269411-1872685986.1494269380 \
	&& wget http://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz 

	# Open port 80
	EXPOSE 80


Tämän jälkeen loin itse kontin (container), eli image/virtuaalikoneen, jota käytän.

Tähän loin oman function powershelliä varten.

	# Creating nagios container
	function dnagios {
	$kpl = 10
	[string]$hosts = ""

	  for ($i=1;$i -le $kpl;$i++) {
	    $r = $i+2
	    $hosts = $hosts + "--add-host=""puppetagent$i puppetagent$i.local"":172.17.0.$r "
	  }

	$params = "--memory=""1024m"" --name nagios --detach --interactive --tty --hostname=""nagios nagios.local"" $hosts --add-host=""puppetmaster puppetmaster.local"":172.17.0.2 --ip 172.17.0.100 --publish 3080:80 --publish 3022:22 nagios_img"

	$prms = $params.split(" ")
	docker run $prms
	}
	
Kun kone oli valmiina, aloitin ensin käymällä läpi nagioksen asennus dokumentaatiota ja asentamalla itse ohjelman. Tarkoituksena on kun siirtää agenttikoneelle vain binaryt ja config tiedostot. Eikä suorittaa kääntämistä kohdekoneella.

(Nagios 2017.)

## Vaihe 1 - Moduulin luominen, ohjelmien asentaminen ja käyttäjän luominen

Ensin tehdään uudet kansiot

	$ sudo mkdir -p /etc/puppet/modules/{manifests,templates}

Sitten luodaan ensimmäinen vedos init.pp tiedostosta. 
Tässä ei ole tarkoitus tehdä vielä kaikkia määrityksiä, vaan nähdä, että ohjelmat ylipäätäänsä 
edes asentuu. Eli toteutamme tämän vaiheittain.

	$ sudo nano /etc/puppet/modules/manifests/init.pp

	class nagios {

		# Set global package parameters
		Package { ensure => 'installed', allowcdrom => 'true' }
	
		# Install LAMP
		package { 'apache2': }
		package { 'mysql-server': }
		package { 'php7.0': }
		package { 'php-pear': }
		package { 'libapache2-mod-php7.0': }
		package { 'php7.0-mysql': }
	
		# Creating group and user for nagios
	 	group { 'nagcmd': ensure => 'present' }
	
	       user { 'nagios':
	                ensure => 'present',
	                password => 'Nagios123', 
	                groups => [nagcmd, www-data], 
	                shell => '/usr/sbin/nologin', 
	                comment => 'Nagios daemon user'
	        }


}

(Linode 2016).
(Puppet Cookbook 2015.)

## Testataan vaiheessa 1 olevaa moduulia

Käytetään omaa apuppet aliasta, jotta voimme testata nykyhetken.

	$ apuppet nagios
	Notice: Compiled catalog for xubuntu.tielab.haaga-helia.fi in environment production in 0.39 seconds
	Notice: /Stage[main]/Nagios/Package[libapache2-mod-php7.0]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[php-pear]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[php7.0-mysql]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[mysql-server]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[php7.0]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Group[nagcmd]/ensure: created
	Notice: /Stage[main]/Nagios/User[nagios]/ensure: created
	Notice: Finished catalog run in 53.75 seconds

## Varmistetaan vaihteen 1 lopputulos

Tarkistetaan, että käyttäjä nagios on luotuna ja, että sillä ei voi kirjautua

	$ cat /etc/passwd | grep nagios 
	nagios:x:1000:1001:Nagios daemon user:/home/nagios:/usr/sbin/nologin

Tarkistetaan, että käyttäjä nagios on ryhmissä nagcmd ja www-data

	$ cat /etc/group |grep nagios
	www-data:x:33:nagios <--
	nagcmd:x:1000:nagios <--
	nagios:x:1001: <-- käyttäjätunnus

Asennetaan curl, jotta voidaan todentaa apache testisivun toiminta

	$ sudo apt-get install -y curl
	$ curl -I localhost
	HTTP/1.1 200 OK
	Date: Wed, 03 May 2017 11:19:58 GMT
	Server: Apache/2.4.18 (Ubuntu)
	Last-Modified: Wed, 03 May 2017 10:55:21 GMT
	ETag: "2c39-54e9c7e1febe6"
	Accept-Ranges: bytes
	Content-Length: 11321
	Vary: Accept-Encoding
	Content-Type: text/html

Katsotaan, että mysql palvelu on käynnissä

	$ sudo systemctl status mysql
	● mysql.service - MySQL Community Server
	   Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: enabled)
	   Active: active (running) since Wed 2017-05-03 11:02:52 UTC; 25min ago
	 Main PID: 30974 (mysqld)
	   CGroup: /system.slice/mysql.service
	           └─30974 /usr/sbin/mysqld
	
	May 03 11:02:51 xubuntu systemd[1]: Starting MySQL Community Server...
	May 03 11:02:52 xubuntu systemd[1]: Started MySQL Community Server.

## Vaihe 2 - Määrittelyjen lisäys palveluille

Nyt kun ohjelmat on asennettu, voidaan tehdä määritykset, ottaa niistä määritystiedostot
talteen ja lisätä ne init.pp asennustiedostoon.

Lisätään palveluihin määritystiedostoja template resourcen avulla.

Latasin netinstall.pp https://github.com/example42/puppi/blob/master/manifests/netinstall.pp

(Superuser 2012.) 

(Bitfield Consulting 2010.)

# Lähteet

Bitfield Consulting 2010. Puppet and MySQL: create databases and users.
Luettavissa: http://bitfieldconsulting.com/puppet-and-mysql-create-databases-and-users. Luettu: 3.5.2017.

Docker docs 2017. Dockerfile reference. Luettavissa: https://docs.docker.com/engine/reference/builder/. Luettu: 8.5.2017.

Linode 2016. Install LAMP on Ubuntu 16.04.
Luettavissa: https://www.linode.com/docs/web-servers/lamp/install-lamp-on-ubuntu-16-04. Luettu 3.5.2017.

Nagios 2017. Nagios - Installing Nagios Core from Source. Luettavissa: https://assets.nagios.com/downloads/nagioscore/docs/Installing_Nagios_Core_From_Source.pdf#_ga=2.238731145.863927744.1494269411-1872685986.1494269380. Luettu 8.5.2017.

Puppet Cookbook 2015. You want some resource examples.
Luettavissa: https://www.puppetcookbook.com/posts/show-resources-with-ralsh.html. Luettu 3.5.2017.

Superuser 2012. Install a source package with puppet.
Luettavissa: https://superuser.com/questions/415047/install-a-source-package-with-puppet. Luettu 3.5.2017.
