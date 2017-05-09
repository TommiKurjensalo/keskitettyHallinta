# Nagios moduulin luonti

# KESKEN

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

	$params = "--memory=""1024m"" --name nagios --detach --interactive --tty --hostname=""nagios nagios.local"" $hosts --add-host=""puppetmaster puppetmaster.local"":172.17.0.2 --publish 3080:80 --publish 3022:22 nagios_img"

	$prms = $params.split(" ")
	docker run $prms
	}
	
Kun kone oli valmiina, aloitin ensiksi käymällä läpi nagioksen asennus dokumentaation ja asentamalla itse ohjelman. Tarkoituksena on kun siirtää agenttikoneelle vain binaryt ja config tiedostot. Eikä suorittaa kääntämistä kohdekoneella.

(Nagios 2017.)

## Nagioksen asennus

	nagios:/tmp$ sudo useradd nagios && sudo groupadd nagcmd
	nagios:/tmp$ sudo usermod -a -G nagcmd nagios
	nagios:/tmp$ sudo usermod -a -G nagios,nagcmd www-data

Muutan /tmp kansion oikeuksia, jotta ei tarvitse niinpaljoa sudotella.

	insp@nagios:/tmp$ sudo chmod 777 -R /tmp/* 

Puretaan tervapallot

	insp@nagios:/tmp$ tar zxvf nagios-4.3.1.tar.gz && tar zxvf nagios-plugins-2.2.1.tar.gz
	
Mennään nagios kansioon ja ajetaan configure

	insp@nagios:/tmp$ cd nagios-4.3.1
	insp@nagios:/tmp/nagios-4.3.1$ sudo ./configure --with-command-group=nagcmd --with-mail=/usr/bin/sendmail --with-httpd-conf=/etc/apache2/
	
Asennetaan nagios

	insp@nagios:/tmp/nagios-4.3.1$ sudo make all && sudo make install && sudo make install-init && sudo make install-config && sudo make install-commandmode && sudo make install-webconf
	insp@nagios:/tmp/nagios-4.3.1$ sudo chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
	insp@nagios:/tmp/nagios-4.3.1$ sudo a2ensite nagios
	ERROR: Site nagios does not exist!
	insp@nagios:/tmp/nagios-4.3.1$ sudo a2enmod rewrite cgi
	Enabling module rewrite.
	AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to
	Enabling module cgi.
	To activate the new configuration, you need to run:
	service apache2 restart

a2ensite nagios aiheutti närää, koska huomasin että nagios.conf linkkaus ei onnistunut oikein.

	--pätkästy
	*** External command directory configured ***

	/usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2//nagios.conf
	if [ 0 -eq 1 ]; then \
			ln -s /etc/apache2//nagios.conf /etc/apache2/sites-enabled/nagios.conf; \
	fi
	--

Loin siis fqdn.conf tiedoston ja tein linkin sille.

	nagios:/etc/apache2/conf-available$ cat /etc/apache2/conf-available/fqdn.conf
	 ServerName localhost
	
	nagios:/etc/apache2/conf-enabled$ sudo ln -s ../conf-available/fqdn.conf /etc/apache2/conf-enabled/fqdn.conf
	nagios:/etc/apache2/conf-enabled$ sudo /etc/init.d/apache2 restart

Näin ollen ei enää virheilmoituksia ilmennyt.

Loin nagiosadmin web käyttäjätunnuksen ja annoin sille salasanan

	nagios:/$ sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin	
	New password:
	Re-type new password:
	Adding password for user nagiosadmin

## Asennetaan nagios pluginit

	nagios:/$ cd /tmp/nagios-plugins-2.2.1
	nagios:/tmp/nagios-plugins-2.2.1$ sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagios
	nagios:/tmp/nagios-plugins-2.2.1$ sudo make && sudo make install
	
Jos nagioksen haluaa käynnistymään automaattisesti aja seuraava komento

	nagios:/$ sudo update-rc.d nagios defaults
	
Käynnistetään nagios palvelus

	nagios:/$ sudo service nagios start
	
Testataan toimivuus

	nagios:/$ curl --user nagiosadmin:xxxx localhost/nagios/
	
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
	
	<html>
	<head>
			<meta name="ROBOTS" content="NOINDEX, NOFOLLOW">
	<script LANGUAGE="javascript">
			var n = Math.round(Math.random() * 10000000000);
			document.write("<title>Nagios Core on " + window.location.hostname + "</title>");
			document.cookie = "NagFormId=" + n.toString(16);
	</script>
			<link rel="shortcut icon" href="images/favicon.ico" type="image/ico">
	</head>

.. Homma toimii!

Seuraavaksi olisi hyvä hetki katsoa, että mitä kaikkea tietoa tarvitsee siirtää uuteen koneeseen, jotta nagioksen voi helposti
siirtää ilman kääntämistyötä.


	
	
		
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

DigitalOcean 2017. How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 16.04 Server.
Luettavissa: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server. Luettu: 9.5.2017.

Docker docs 2017. Dockerfile reference. Luettavissa: https://docs.docker.com/engine/reference/builder/. Luettu: 8.5.2017.

Linode 2016. Install LAMP on Ubuntu 16.04.
Luettavissa: https://www.linode.com/docs/web-servers/lamp/install-lamp-on-ubuntu-16-04. Luettu 3.5.2017.

Nagios 2017. Nagios - Installing Nagios Core from Source. Luettavissa: https://assets.nagios.com/downloads/nagioscore/docs/Installing_Nagios_Core_From_Source.pdf#_ga=2.238731145.863927744.1494269411-1872685986.1494269380. Luettu 8.5.2017.

Puppet Cookbook 2015. You want some resource examples.
Luettavissa: https://www.puppetcookbook.com/posts/show-resources-with-ralsh.html. Luettu 3.5.2017.

Superuser 2012. Install a source package with puppet.
Luettavissa: https://superuser.com/questions/415047/install-a-source-package-with-puppet. Luettu 3.5.2017.
