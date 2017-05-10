# Nagios moduulin luonti

Tarkoituksena on asentaa apache, nagios ja luoda niille ainakin perusmääritykset.

Harjoituksen vaihe 1 tehtiin Haaga-Helia Pasilan luokassa 5004 PC 15. 
Käyttöjärjestelmänä toimi Xubuntu 16.04.2, joka pyöri usb-tikulta live-tilassa.

Kotona käytän Docker for Windows v 17.03.1-ce työkalua, jolla olen luonut puppetmaster ja puppetagent kontteja (container).
Eli käytännössä sama kuin käyttäisi vagranttia, mutta Dockerin avulla voi tehdä paljon muutakin.

Hyvä lopputulos olisi se, että nagioksen sivulle pääsisi kiinni ja siellä olisi
ainakin 1 kone, jota valvotaan, että kone on päällä. Katsotaan kuinka pitkälle pääsen.
Tähän käytetään nagioksen ping toimintoa.

Toteutunut lopputulos oli kuten kuvasin, mutta koneina oli paikallinen linux ja windows työasema.

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

Loin sitten linkin käsin.

	nagios:/etc/apache2/conf-available$ ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/nagios.conf
	
Loin myös fqdn.conf tiedoston ja tein linkin sille.

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

## Nagioksen siirto toiselle koneelle

Tarkoituksena on nyt testata, että mitä kaikkea tietoa tarvitsee siirtää toiseen koneeseen, jotta nagiosta voidaan käyttää.

	nagios:~$ cat /etc/init.d/nagios
	--leikattu
	# Our install-time configuration.
	prefix=/usr/local/nagios
	exec_prefix=${prefix}
	NagiosBin=${exec_prefix}/bin/nagios
	NagiosCfgFile=${prefix}/etc/nagios.cfg
	NagiosCfgtestFile=${prefix}/var/nagios.configtest
	NagiosStatusFile=${prefix}/var/status.dat
	NagiosRetentionFile=${prefix}/var/retention.dat
	NagiosCommandFile=${prefix}/var/rw/nagios.cmd
	NagiosVarDir=${prefix}/var
	NagiosRunFile=${prefix}/var/nagios.lock
	NagiosLockDir=/var/lock/subsys
	NagiosLockFile=nagios
	NagiosCGIDir=${exec_prefix}/sbin
	NagiosUser=nagios
	NagiosGroup=nagios
	checkconfig="true"
	--leikattu

Kyseisen tietojen perusteella voisin päätellä, että /usr/local/nagios kansion siirtäminen on riittävä nagioksen osalta.
Tietenkin apache2 liittyvät määrittelytiedostot on hyvä ottaa talteen.

Eli seuraavat asiat pitää ottaa huomioon modulia tekiessä.

- /usr/local/nagios kansion siirto (varmista oikeudet nagios:nagios)
- /etc/apache2 kansion siirto (varmista oikeudet)
- /etc/init.d/nagios tiedoston siirto (varmista oikeudet)
- nagios käyttäjän luonti
- nagcmd ryhmän luonti
- nagios käyttäjän liittäminen nagcmd ryhmään
- www-data käyttäjän liittäminen nagios ja nagcmd ryhmiin
- nagios palvelun luonti

Pakataan kansiot kokonaisineen hakemistopolkuineen ja käytetään varmuudenvuoksi -p parametriä. Vaikka sitä nyt ei ehkä olisi tarvinnut.

Ote tar --help ohjeistuksesta.
-p, --preserve-permissions, --same-permissions
extract information about file permissions
(default for superuser)

	nagios:~$ sudo tar cvpfz /tmp/apache2-backup.tar.gz /etc/apache2/*
	nagios:~$ sudo tar cvpfz /tmp/nagios-backup.tar.gz /usr/local/nagios/*

	(Askubuntu 2012.)

Siirretään tiedostot saataville

	nagios:~$ sudo cp /tmp/apache2-backup.tar.gz /var/www/html
	nagios:~$ sudo cp /tmp/nagios-backup.tar.gz /var/www/html
	nagios:~$ sudo cp /etc/init.d/nagios /var/www/html/nagiosD

## Testiajo

Luodaan uusi kontti ubuntu 16.04.2 nagtest, johon asennan build-essential apache2 php apache2-mod-php7.0 php-gd libgd-dev unzip paketit ja siirrän backup tervapallot.

Osoite 172.17.0.2 on tuo nagios kone. Siirrän paketit nyt wgetillä, koska sattui sopivasti olemaan apache2 palvelu päällä.

	nagtest:~$ wget http://172.17.0.2/apache2-backup.tar.gz
	nagtest:~$ wget http://172.17.0.2/nagios-backup.tar.gz
	nagtest:~$ wget http://172.17.0.3/nagiosD

Sitten pakettien purku, käyttäjien luonti, palvelun käynnistäminen ja sivun toimivuuden testaaminen curlilla.

	nagtest:~$ sudo tar xvpfz apache2-backup.tar.gz -C /
	nagtest:~$ sudo tar xvpfz nagios-backup.tar.gz -C /
	(Stack overflow 2013.)
	nagtest:~$ sudo usermod -a -G nagcmd nagios
	nagtest:~$ sudo usermod -a -G nagios,nagcmd www-data
	nagtest:~$ sudo service apache2 start
	nagtest:~$ curl localhost/nagios/
	<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
	<html><head>
	<title>401 Unauthorized</title>
	</head><body>
	<h1>Unauthorized</h1>
	<p>This server could not verify that you
	are authorized to access the document
	requested.  Either you supplied the wrong
	credentials (e.g., bad password), or your
	browser doesn't understand how to supply
	the credentials required.</p>
	<hr>
	<address>Apache/2.4.18 (Ubuntu) Server at localhost Port 80</address>
	</body></html>

Näyttää toimivan, nyt voi siirtyä moduulin luomiseen, kun tietää työjärjestyksen.
		
## Vaihe 1 - Moduulin luominen, ohjelmien asentaminen ja käyttäjän luominen

Ensin tehdään uudet kansiot

	$ sudo mkdir -p /etc/puppet/modules/nagios/{manifests,templates,files}

Sitten luodaan ensimmäinen vedos init.pp tiedostosta. 
Tässä ei ole tarkoitus tehdä vielä kaikkia määrityksiä, vaan nähdä, että ohjelmat ylipäätäänsä 
edes asentuu. Eli toteutamme tämän vaiheittain.

	$ sudoedit /etc/puppet/modules/nagios/manifests/init.pp

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
(Puppet CookBook 2015a.)

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

Siirretään nagios koneelta apache ja nagios backupit

	puppetmaster::/etc/puppet/modules/nagios/files$ wget http://172.17.0.3/nagios-backup.tar.gz
	puppetmaster::/etc/puppet/modules/nagios/files$ wget http://172.17.0.3/apache2-backup.tar.gz

Tämän hetkinen init.pp
	
	puppetmaster::/etc/puppet/modules/nagios/manifests$ cat init.pp
	class nagios {

        # Set global package parameters
        Package { ensure => 'installed', allowcdrom => 'true' }

        # Install apache2, php and required libs
        package { 'wget': }
        package { 'build-essential': }
        package { 'apache2': }
        package { 'php': }
        package { 'apache2-mod-php7.0': }
        package { 'php-gd': }
        package { 'libgd-dev': }
        package { 'unzip': }

        # Settings for service apache2
        # Making apache2 virtualhost
        file { '/etc/apache2/sites-available/010-nagioslocal.conf':
                        ensure  => 'file',
                        content => template('nagios/010-nagioslocal.erb'),
        }

        # Creating link to apache2 sites-available to sites-enabled
        file { '/etc/apache2/sites-enabled/010-nagioslocal.conf':
                ensure => 'link',
                target => '../sites-available/010-nagioslocal.conf',
                notify => Service['apache2'],
        }

        # Changing apache2 to start automatically during bootup
        service { 'apache2':
                enable          => 'true',
                ensure          => 'running',
                provider        => 'systemd',
                require         => Package['apache2'],
        }

        # Creating group and user for nagios
        group { 'nagcmd': ensure => 'present' }
		group { 'nagios': ensure => 'present' }

        user { 'nagios':
                ensure  => 'present',
                gid     => '1001',
                uid     => '1001',
                groups  => [nagcmd, www-data],
                shell   => '/usr/sbin/nologin',
                comment => 'Nagios daemon user',
        }

		        user { 'www-data':
                groups => [nagios,nagcmd],
        }

        # Fetch tarbals
        file { '/tmp/nagios-backup.tar.gz':
				ensure => 'file',
                source => 'puppet:///modules/nagios/nagios-backup.tar.gz',
        }

        file { '/tmp/apache2-backup.tar.gz':
				ensure => 'file',
                source => 'puppet:///modules/nagios/apache2-backup.tar.gz',
        }

        # Unpacking nagios and apache tarbals
        exec { 'nagios-backup.tar.gz':
                path    => ['/bin', '/usr/bin', '/usr/lib'],
                cwd     => '/tmp',
                command => 'tar xvpfz nagios-backup.tar.gz -C /',
                onlyif  => 'test -f nagios-backup.tar.gz',
        }

        exec { 'apache2-backup.tar.gz':
                path    => ['/bin', '/usr/bin', '/usr/lib'],
                cwd     => '/tmp',
                command => 'tar xvpfz apache2-backup.tar.gz -C /',
                onlyif  => 'test -f apache2-backup.tar.gz',
        }
	}

(Puppet Documentation a.)
(Puppet Documentation b.)
(Puppet CookBook 2015b.)

Agentilla testiajoa

	puppetagent10:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Error: Could not retrieve catalog from remote server: Error 400 on SERVER: invalid byte sequence in US-ASCII at /etc/puppet/modules/nagios/manifests/init.pp:1 on node puppetagent10.local
	Warning: Not using cache on failed catalog
	Error: Could not retrieve catalog; skipping run

Törmäsin validointi virheeseen charsetin takia. Yritin pakottaa utf8 moodia päälle ja ties mitä, mutta ainoa toimiva keino oli se, että etsin vain init.pp tiedostosta kohdat jotka aiheuttivat ongelman. Nano näytti osan virheistä(?) punaisella ja osassa kohtaa oli 2x välilyönti, jonka poistamalla vika korjaantui.

	puppetmaster:/etc/puppet/modules/nagios/manifests$ puppet parser validate init.pp
	Error: Could not parse for environment production: invalid byte sequence in US-ASCII at /etc/puppet/modules/nagios/manifests/init.pp:1

Uusi yritys..

	@puppetagent10:~$ sudo puppet agent -t
	[sudo] password for insp:
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetagent10.local
	Info: Applying configuration version '1494423808'
	Notice: /Stage[main]/Nagios/Package[build-essential]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Exec[nagios-backup.tar.gz]/returns: executed successfully
	Notice: /Stage[main]/Nagios/Package[libgd-dev]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[php]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/File[/etc/apache2/sites-available/010-nagioslocal.conf]/ensure: defined content as '{md5}8d9629a1bc0721f1cabfb3889ab52413'
	Notice: /Stage[main]/Nagios/File[/etc/apache2/sites-enabled/010-nagioslocal.conf]/ensure: created
	Info: /Stage[main]/Nagios/File[/etc/apache2/sites-enabled/010-nagioslocal.conf]: Scheduling refresh of Service[apache2]
	Notice: /Stage[main]/Nagios/Package[php-gd]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[apache2-mod-php7.0]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Exec[apache2-backup.tar.gz]/returns: executed successfully
	Notice: /Stage[main]/Nagios/Group[nagcmd]/ensure: created
	Notice: /Stage[main]/Nagios/User[nagios]/ensure: created
	Error: Could not set groups on user[www-data]: Execution of '/usr/sbin/usermod -G nagcmd,nagios www-data' returned 6: usermod: group 'nagios' does not exist
	Error: /Stage[main]/Nagios/User[www-data]/groups: change from  to nagcmd,nagios failed: Could not set groups on user[www-data]: Execution of '/usr/sbin/usermod -G nagcmd,nagios www-data' returned 6: usermod: group 'nagios' does not exist
	Error: Execution of '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install apache2' returned 100: Reading package lists...
	Building dependency tree...
	Reading state information...
	The following additional packages will be installed:
	  apache2-data apache2-utils ssl-cert
	Suggested packages:
	  www-browser apache2-doc apache2-suexec-pristine | apache2-suexec-custom ufw
	  openssl-blacklist
	The following NEW packages will be installed:
	  apache2 apache2-data apache2-utils ssl-cert
	0 upgraded, 4 newly installed, 0 to remove and 9 not upgraded.
	Need to get 346 kB of archives.
	After this operation, 1777 kB of additional disk space will be used.
	Get:1 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2-utils amd64 2.4.18-2ubuntu3.1 [81.3 kB]
	Get:2 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2-data all 2.4.18-2ubuntu3.1 [162 kB]
	Get:3 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2 amd64 2.4.18-2ubuntu3.1 [86.7 kB]
	Get:4 http://archive.ubuntu.com/ubuntu xenial/main amd64 ssl-cert all 1.0.37 [16.9 kB]
	debconf: delaying package configuration, since apt-utils is not installed
	Fetched 346 kB in 4s (71.4 kB/s)
	Selecting previously unselected package apache2-utils.
	(Reading database ... 26118 files and directories currently installed.)
	Preparing to unpack .../apache2-utils_2.4.18-2ubuntu3.1_amd64.deb ...
	Unpacking apache2-utils (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package apache2-data.
	Preparing to unpack .../apache2-data_2.4.18-2ubuntu3.1_all.deb ...
	Unpacking apache2-data (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package apache2.
	Preparing to unpack .../apache2_2.4.18-2ubuntu3.1_amd64.deb ...
	Unpacking apache2 (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package ssl-cert.
	Preparing to unpack .../ssl-cert_1.0.37_all.deb ...
	Unpacking ssl-cert (1.0.37) ...
	Processing triggers for systemd (229-4ubuntu16) ...
	Setting up apache2-utils (2.4.18-2ubuntu3.1) ...
	Setting up apache2-data (2.4.18-2ubuntu3.1) ...
	Setting up apache2 (2.4.18-2ubuntu3.1) ...

	Configuration file '/etc/apache2/sites-available/default-ssl.conf'
	 ==> File on system created by you or by a script.
	 ==> File also in package provided by package maintainer.
	 ==> Using current old file as you requested.
	ERROR: Module mpm_prefork is enabled - cannot proceed due to conflicts. It needs to be disabled first!
	dpkg: error processing package apache2 (--configure):
	 subprocess installed post-installation script returned error exit status 1
	Setting up ssl-cert (1.0.37) ...
	Processing triggers for systemd (229-4ubuntu16) ...
	Errors were encountered while processing:
	 apache2
	E: Sub-process /usr/bin/dpkg returned an error code (1)
	Error: /Stage[main]/Nagios/Package[apache2]/ensure: change from purged to present failed: Execution of '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install apache2' returned 100: Reading package lists...
	Building dependency tree...
	Reading state information...
	The following additional packages will be installed:
	  apache2-data apache2-utils ssl-cert
	Suggested packages:
	  www-browser apache2-doc apache2-suexec-pristine | apache2-suexec-custom ufw
	  openssl-blacklist
	The following NEW packages will be installed:
	  apache2 apache2-data apache2-utils ssl-cert
	0 upgraded, 4 newly installed, 0 to remove and 9 not upgraded.
	Need to get 346 kB of archives.
	After this operation, 1777 kB of additional disk space will be used.
	Get:1 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2-utils amd64 2.4.18-2ubuntu3.1 [81.3 kB]
	Get:2 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2-data all 2.4.18-2ubuntu3.1 [162 kB]
	Get:3 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2 amd64 2.4.18-2ubuntu3.1 [86.7 kB]
	Get:4 http://archive.ubuntu.com/ubuntu xenial/main amd64 ssl-cert all 1.0.37 [16.9 kB]
	debconf: delaying package configuration, since apt-utils is not installed
	Fetched 346 kB in 4s (71.4 kB/s)
	Selecting previously unselected package apache2-utils.
	(Reading database ... 26118 files and directories currently installed.)
	Preparing to unpack .../apache2-utils_2.4.18-2ubuntu3.1_amd64.deb ...
	Unpacking apache2-utils (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package apache2-data.
	Preparing to unpack .../apache2-data_2.4.18-2ubuntu3.1_all.deb ...
	Unpacking apache2-data (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package apache2.
	Preparing to unpack .../apache2_2.4.18-2ubuntu3.1_amd64.deb ...
	Unpacking apache2 (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package ssl-cert.
	Preparing to unpack .../ssl-cert_1.0.37_all.deb ...
	Unpacking ssl-cert (1.0.37) ...
	Processing triggers for systemd (229-4ubuntu16) ...
	Setting up apache2-utils (2.4.18-2ubuntu3.1) ...
	Setting up apache2-data (2.4.18-2ubuntu3.1) ...
	Setting up apache2 (2.4.18-2ubuntu3.1) ...

	Configuration file '/etc/apache2/sites-available/default-ssl.conf'
	 ==> File on system created by you or by a script.
	 ==> File also in package provided by package maintainer.
	 ==> Using current old file as you requested.
	ERROR: Module mpm_prefork is enabled - cannot proceed due to conflicts. It needs to be disabled first!
	dpkg: error processing package apache2 (--configure):
	 subprocess installed post-installation script returned error exit status 1
	Setting up ssl-cert (1.0.37) ...
	Processing triggers for systemd (229-4ubuntu16) ...
	Errors were encountered while processing:
	 apache2
	E: Sub-process /usr/bin/dpkg returned an error code (1)
	Error: /Stage[main]/Nagios/Service[apache2]: Provider systemd is not functional on this host
	Notice: Finished catalog run in 384.06 seconds

Ei ihan kaikki toiminnot onnistuneet, koska nähtävästi nagios ryhmää ei ole olemassa ja näin ollen käyttäjää www-data ei voida siihen liittää.
Ongelmana oli myös se, että pohjalla oli jo tuotuna apache2 konfiguraatiot, eikä oletuksena näin pitäisi olla kun kone on ns. tyhjä.
Provider määritelmä pitänee myös vaihtaa toiseksi, koska systemd:tä ei ole tuettu.

## Korjaukset

Kommentoidaan provider rivi pois init.pp:stä ja lisätään rivi, joka luo ryhmän nagios.

	# Changing apache2 to start automatically during bootup
	service { 'apache2':
                enable          => 'true',
                ensure          => 'running',
	#           provider        => 'systemd',
                require         => Package['apache2'],
        }
	# Creating group and user for nagios
	group { 'nagios': ensure => 'present' }

Kopioidaan nagiosD /etc/init.d kansioon ja laitetaan näin testimielessä 755 oikeudet.

Lisätään tervapallon purkuun parametri --overwrite, koska apachen asennusjälkeen haluemme korvata oletus määritystiedostot omilla.
	
Otetaan toinen agenttikone käyttöön, mitä ei olla vielä "pilattu" testailulla.

	puppetagent3:~$ sudo puppet agent -t
	puppetagent3:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetagent3.local
	Info: Applying configuration version '1494426695'
	Notice: /Stage[main]/Nagios/Package[build-essential]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/File[/etc/init.d/nagios]/ensure: defined content as '{md5}d22af5d0377f3d64f4136dcd743de62f'
	Notice: /Stage[main]/Nagios/Package[libgd-dev]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[php]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/File[/tmp/apache2-backup.tar.gz]/ensure: defined content as '{md5}1096cb8a8eaa46a4463b391468328638'
	Error: Could not set 'file' on ensure: No such file or directory @ dir_s_rmdir - /etc/apache2/sites-available/010-nagioslocal.conf20170510-38-1phm3rj.lock at 21:/etc/puppet/modules/nagios/manifests/init.pp
	Error: Could not set 'file' on ensure: No such file or directory @ dir_s_rmdir - /etc/apache2/sites-available/010-nagioslocal.conf20170510-38-1phm3rj.lock at 21:/etc/puppet/modules/nagios/manifests/init.pp
	Wrapped exception:
	No such file or directory @ dir_s_rmdir - /etc/apache2/sites-available/010-nagioslocal.conf20170510-38-1phm3rj.lock
	Error: /Stage[main]/Nagios/File[/etc/apache2/sites-available/010-nagioslocal.conf]/ensure: change from absent to file failed: Could not set 'file' on ensure: No such file or directory @ dir_s_rmdir - /etc/apache2/sites-available/010-nagioslocal.conf20170510-38-1phm3rj.lock at 21:/etc/puppet/modules/nagios/manifests/init.pp
	Error: Could not set 'link' on ensure: No such file or directory @ dir_chdir - /etc/apache2/sites-enabled at 28:/etc/puppet/modules/nagios/manifests/init.pp
	Error: Could not set 'link' on ensure: No such file or directory @ dir_chdir - /etc/apache2/sites-enabled at 28:/etc/puppet/modules/nagios/manifests/init.pp
	Wrapped exception:
	No such file or directory @ dir_chdir - /etc/apache2/sites-enabled
	Error: /Stage[main]/Nagios/File[/etc/apache2/sites-enabled/010-nagioslocal.conf]/ensure: change from absent to link failed: Could not set 'link' on ensure: No such file or directory @ dir_chdir - /etc/apache2/sites-enabled at 28:/etc/puppet/modules/nagios/manifests/init.pp
	Notice: /Stage[main]/Nagios/Package[php-gd]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[apache2-mod-php7.0]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Group[nagios]/ensure: created
	Notice: /Stage[main]/Nagios/File[/tmp/nagios-backup.tar.gz]/ensure: defined content as '{md5}dd136ed1995815746acb64abf423ad93'
	Notice: /Stage[main]/Nagios/Exec[apache2-backup.tar.gz]/returns: executed successfully
	Notice: /Stage[main]/Nagios/Group[nagcmd]/ensure: created
	Notice: /Stage[main]/Nagios/User[nagios]/ensure: created
	Notice: /Stage[main]/Nagios/User[www-data]/groups: groups changed '' to 'nagcmd,nagios'
	Error: Execution of '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install apache2' returned 100: Reading package lists...
	Building dependency tree...
	Reading state information...
	The following additional packages will be installed:
	  apache2-data apache2-utils ssl-cert
	Suggested packages:
	  www-browser apache2-doc apache2-suexec-pristine | apache2-suexec-custom ufw
	  openssl-blacklist
	The following NEW packages will be installed:
	  apache2 apache2-data apache2-utils ssl-cert
	0 upgraded, 4 newly installed, 0 to remove and 9 not upgraded.
	Need to get 346 kB of archives.
	After this operation, 1777 kB of additional disk space will be used.
	Get:1 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2-utils amd64 2.4.18-2ubuntu3.1 [81.3 kB]
	Get:2 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2-data all 2.4.18-2ubuntu3.1 [162 kB]
	Get:3 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2 amd64 2.4.18-2ubuntu3.1 [86.7 kB]
	Get:4 http://archive.ubuntu.com/ubuntu xenial/main amd64 ssl-cert all 1.0.37 [16.9 kB]
	debconf: delaying package configuration, since apt-utils is not installed
	Fetched 346 kB in 0s (405 kB/s)
	Selecting previously unselected package apache2-utils.
	(Reading database ... 26118 files and directories currently installed.)
	Preparing to unpack .../apache2-utils_2.4.18-2ubuntu3.1_amd64.deb ...
	Unpacking apache2-utils (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package apache2-data.
	Preparing to unpack .../apache2-data_2.4.18-2ubuntu3.1_all.deb ...
	Unpacking apache2-data (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package apache2.
	Preparing to unpack .../apache2_2.4.18-2ubuntu3.1_amd64.deb ...
	Unpacking apache2 (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package ssl-cert.
	Preparing to unpack .../ssl-cert_1.0.37_all.deb ...
	Unpacking ssl-cert (1.0.37) ...
	Processing triggers for systemd (229-4ubuntu16) ...
	Setting up apache2-utils (2.4.18-2ubuntu3.1) ...
	Setting up apache2-data (2.4.18-2ubuntu3.1) ...
	Setting up apache2 (2.4.18-2ubuntu3.1) ...

	Configuration file '/etc/apache2/sites-available/default-ssl.conf'
	 ==> File on system created by you or by a script.
	 ==> File also in package provided by package maintainer.
	 ==> Using current old file as you requested.
	ERROR: Module mpm_prefork is enabled - cannot proceed due to conflicts. It needs to be disabled first!
	dpkg: error processing package apache2 (--configure):
	 subprocess installed post-installation script returned error exit status 1
	Setting up ssl-cert (1.0.37) ...
	Processing triggers for systemd (229-4ubuntu16) ...
	Errors were encountered while processing:
	 apache2
	E: Sub-process /usr/bin/dpkg returned an error code (1)
	Error: /Stage[main]/Nagios/Package[apache2]/ensure: change from purged to present failed: Execution of '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install apache2' returned 100: Reading package lists...
	Building dependency tree...
	Reading state information...
	The following additional packages will be installed:
	  apache2-data apache2-utils ssl-cert
	Suggested packages:
	  www-browser apache2-doc apache2-suexec-pristine | apache2-suexec-custom ufw
	  openssl-blacklist
	The following NEW packages will be installed:
	  apache2 apache2-data apache2-utils ssl-cert
	0 upgraded, 4 newly installed, 0 to remove and 9 not upgraded.
	Need to get 346 kB of archives.
	After this operation, 1777 kB of additional disk space will be used.
	Get:1 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2-utils amd64 2.4.18-2ubuntu3.1 [81.3 kB]
	Get:2 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2-data all 2.4.18-2ubuntu3.1 [162 kB]
	Get:3 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 apache2 amd64 2.4.18-2ubuntu3.1 [86.7 kB]
	Get:4 http://archive.ubuntu.com/ubuntu xenial/main amd64 ssl-cert all 1.0.37 [16.9 kB]
	debconf: delaying package configuration, since apt-utils is not installed
	Fetched 346 kB in 0s (405 kB/s)
	Selecting previously unselected package apache2-utils.
	(Reading database ... 26118 files and directories currently installed.)
	Preparing to unpack .../apache2-utils_2.4.18-2ubuntu3.1_amd64.deb ...
	Unpacking apache2-utils (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package apache2-data.
	Preparing to unpack .../apache2-data_2.4.18-2ubuntu3.1_all.deb ...
	Unpacking apache2-data (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package apache2.
	Preparing to unpack .../apache2_2.4.18-2ubuntu3.1_amd64.deb ...
	Unpacking apache2 (2.4.18-2ubuntu3.1) ...
	Selecting previously unselected package ssl-cert.
	Preparing to unpack .../ssl-cert_1.0.37_all.deb ...
	Unpacking ssl-cert (1.0.37) ...
	Processing triggers for systemd (229-4ubuntu16) ...
	Setting up apache2-utils (2.4.18-2ubuntu3.1) ...
	Setting up apache2-data (2.4.18-2ubuntu3.1) ...
	Setting up apache2 (2.4.18-2ubuntu3.1) ...

	Configuration file '/etc/apache2/sites-available/default-ssl.conf'
	 ==> File on system created by you or by a script.
	 ==> File also in package provided by package maintainer.
	 ==> Using current old file as you requested.
	ERROR: Module mpm_prefork is enabled - cannot proceed due to conflicts. It needs to be disabled first!
	dpkg: error processing package apache2 (--configure):
	 subprocess installed post-installation script returned error exit status 1
	Setting up ssl-cert (1.0.37) ...
	Processing triggers for systemd (229-4ubuntu16) ...
	Errors were encountered while processing:
	 apache2
	E: Sub-process /usr/bin/dpkg returned an error code (1)
	Notice: /Stage[main]/Nagios/Service[apache2]: Dependency File[/etc/apache2/sites-enabled/010-nagioslocal.conf] has failures: true
	Notice: /Stage[main]/Nagios/Service[apache2]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/Service[apache2]: Skipping because of failed dependencies
	Notice: Finished catalog run in 359.82 seconds

Uusia virheitä. 

- Ei löytynyt /etc/apache2/sites-available/010-nagioslocal.conf tiedostoa
- apache2 asennuksessa on hämminkiä
- Tiedosto /etc/apache2/sites-available/default-ssl.conf on jo olemassa
- mpm_prefork modulia ei voi käynnistää, koska se on jo olemassa/käynnissä
- apache2 paketin tila epäonnistui muuttumaan tilasta purge -> present

Unohtu myös lisätä nagios käynnistyslistalle rcS.d kansioon.

Muutin määrityksiä niin, että config tiedostoja ei voida kopioida ennenkuin apache2 on asennettuna.

```file``` kohtiin lisäsin ```require => Package['apache2']``` ja ```exec``` lisäsin ```onlyif  => 'test -f xxxxxx-backup.tar.gz && test -f /etc/init.d/apache2'```.

Uusi yritys ja uudet virheet..

	puppetagent5:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetagent5.local
	Info: Applying configuration version '1494430945'
	Notice: /Stage[main]/Nagios/Package[build-essential]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[libgd-dev]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[php]/ensure: ensure changed 'purged' to 'present'
	Error: Could not set 'link' on ensure: No such file or directory @ dir_chdir - /etc/apache2/sites-enabled at 31:/etc/puppet/modules/nagios/manifests/init.pp
	Error: Could not set 'link' on ensure: No such file or directory @ dir_chdir - /etc/apache2/sites-enabled at 31:/etc/puppet/modules/nagios/manifests/init.pp
	Wrapped exception:
	No such file or directory @ dir_chdir - /etc/apache2/sites-enabled
	Error: /Stage[main]/Nagios/File[/etc/apache2/sites-enabled/010-nagioslocal.conf]/ensure: change from absent to link failed: Could not set 'link' on ensure: No such file or directory @ dir_chdir - /etc/apache2/sites-enabled at 31:/etc/puppet/modules/nagios/manifests/init.pp
	Notice: /Stage[main]/Nagios/Package[php-gd]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[apache2-mod-php7.0]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Group[nagios]/ensure: created
	Notice: /Stage[main]/Nagios/Group[nagcmd]/ensure: created
	Notice: /Stage[main]/Nagios/User[nagios]/ensure: created
	Notice: /Stage[main]/Nagios/User[www-data]/groups: groups changed '' to 'nagcmd,nagios'
	Notice: /Stage[main]/Nagios/Package[apache2]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/File[/etc/init.d/nagios]/ensure: defined content as '{md5}d22af5d0377f3d64f4136dcd743de62f'
	Notice: /Stage[main]/Nagios/File[/tmp/apache2-backup.tar.gz]/ensure: defined content as '{md5}1096cb8a8eaa46a4463b391468328638'
	Notice: /Stage[main]/Nagios/File[/etc/apache2/sites-available/010-nagioslocal.conf]/ensure: defined content as '{md5}8d9629a1bc0721f1cabfb3889ab52413'
	Notice: /Stage[main]/Nagios/Service[apache2]: Dependency File[/etc/apache2/sites-enabled/010-nagioslocal.conf] has failures: true
	Warning: /Stage[main]/Nagios/Service[apache2]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/tmp/nagios-backup.tar.gz]/ensure: defined content as '{md5}dd136ed1995815746acb64abf423ad93'
	Notice: Finished catalog run in 156.52 seconds

Nyt oli oikeastaan virheilmoituksenä enää, että ei voida luoda sites-enabled kansioon linkkiä.

Tarkistetaan linkinteko kohta.

	# Making apache2 virtualhost
	file { '/etc/apache2/sites-available/010-nagioslocal.conf':
		ensure  => 'file',
		content => template('nagios/010-nagioslocal.erb'),
	}

Siitähän puuttui ```require => Package['apache2']``` rivi.

Muutoksen jälkeen tuli uusia ilmoituksia.

	Error: Could not start Service[apache2]: Execution of '/usr/sbin/service apache2 start' returned 1: * Starting Apache httpd web server apache2
	 *
	 * The apache2 configtest failed.
	Output of config test was:
	AH00534: apache2: Configuration error: More than one MPM loaded.
	Action 'configtest' failed.
	The Apache error log may have more information.
	Error: /Stage[main]/Nagios/Service[apache2]/ensure: change from stopped to running failed: Could not start Service[apache2]: Execution of '/usr/sbin/service apache2 start' returned 1: * Starting Apache httpd web server apache2
	 *
	 * The apache2 configtest failed.
	Output of config test was:
	AH00534: apache2: Configuration error: More than one MPM loaded.
	Action 'configtest' failed.
	The Apache error log may have more information.
	
**Tarkoittanee sitä, että mods-enabled kansiossa on 2x samoja moduleita. Tämä johtunee siitä, että olen kopioinut koko /etc/apache2 kansion.
Tästä voimme päätellä, että näin EI kannata tehdä.**

Luon siis templatet vain oikeasti tärkeistä tiedostoista, jotka ovat apache2.conf, nagios.conf ja fqdn.conf.
Lopuksi luon näistä linkit conf-available kansiosta conf-enabled kansioon.

Jokohan nyt toimisi.

	@puppetagent6:~$ sudo puppet agent -t
	--leikattu
	E: Failed to fetch http://security.ubuntu.com/ubuntu/pool/main/a/apache2/apache2-utils_2.4.18-2ubuntu3.1_amd64.deb  404  Not Found [IP: 91.189.88.161 80]

	E: Failed to fetch http://security.ubuntu.com/ubuntu/pool/main/a/apache2/apache2-data_2.4.18-2ubuntu3.1_all.deb  404  Not Found [IP: 91.189.88.161 80]

	E: Failed to fetch http://security.ubuntu.com/ubuntu/pool/main/a/apache2/apache2_2.4.18-2ubuntu3.1_amd64.deb  404  Not Found [IP: 91.189.88.161 80]

	E: Unable to fetch some archives, maybe run apt-get update or try with --fix-missing?
	Notice: /Stage[main]/Nagios/File[/etc/init.d/nagios]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/etc/init.d/nagios]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/etc/apache2/sites-available/010-nagioslocal.conf]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/etc/apache2/sites-available/010-nagioslocal.conf]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/etc/apache2/apache2.conf]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/etc/apache2/apache2.conf]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/etc/apache2/sites-enabled/010-nagioslocal.conf]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/etc/apache2/sites-enabled/010-nagioslocal.conf]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/etc/apache2/conf-available/fqdn.conf]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/etc/apache2/conf-available/fqdn.conf]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/tmp/nagios-backup.tar.gz]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/tmp/nagios-backup.tar.gz]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/etc/apache2/conf-enabled/fqdn.conf]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/etc/apache2/conf-enabled/fqdn.conf]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/Service[apache2]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/Service[apache2]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/etc/apache2/conf-available/nagios.conf]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/etc/apache2/conf-available/nagios.conf]: Skipping because of failed dependencies
	Notice: /Stage[main]/Nagios/File[/etc/apache2/conf-enabled/nagios.conf]: Dependency Package[apache2] has failures: true
	Warning: /Stage[main]/Nagios/File[/etc/apache2/conf-enabled/nagios.conf]: Skipping because of failed dependencies
	Notice: Finished catalog run in 122.81 seconds
	--leikattu
	
No eihän se toiminut, koska apt-get ei onnistunut hakemaan paketteja, ts. palvelin hajosi alta.
Mutta ei ollut nyt moduulin syy! Myös riippuvuudet toimivat, koska mitään muuta ei asennettu kun ei voitu asentaa pakettejakaan.

Ajetaan apt-get update ja yritetään uudelleen..

	puppetagent6:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetagent6.local
	Info: Applying configuration version '1494434644'
	Notice: /Stage[main]/Nagios/Package[build-essential]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[libgd-dev]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[php-gd]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[apache2-mod-php7.0]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/Package[apache2]/ensure: ensure changed 'purged' to 'present'
	Notice: /Stage[main]/Nagios/File[/etc/init.d/nagios]/ensure: defined content as '{md5}d22af5d0377f3d64f4136dcd743de62f'
	Notice: /Stage[main]/Nagios/File[/etc/apache2/sites-available/010-nagioslocal.conf]/ensure: defined content as '{md5}8d9629a1bc0721f1cabfb3889ab52413'
	Notice: /Stage[main]/Nagios/File[/etc/apache2/sites-enabled/010-nagioslocal.conf]/ensure: created
	Notice: /Stage[main]/Nagios/File[/etc/apache2/conf-available/fqdn.conf]/ensure: defined content as '{md5}32f2aa34d6e8a388bd4f926f4c31170b'
	Notice: /Stage[main]/Nagios/File[/tmp/nagios-backup.tar.gz]/ensure: defined content as '{md5}dd136ed1995815746acb64abf423ad93'
	Notice: /Stage[main]/Nagios/File[/etc/apache2/conf-enabled/fqdn.conf]/ensure: created
	Info: /Stage[main]/Nagios/File[/etc/apache2/conf-enabled/fqdn.conf]: Scheduling refresh of Service[apache2]
	Notice: /Stage[main]/Nagios/Service[apache2]/ensure: ensure changed 'stopped' to 'running'
	Info: /Stage[main]/Nagios/Service[apache2]: Unscheduling refresh on Service[apache2]
	Notice: /Stage[main]/Nagios/File[/etc/apache2/conf-available/nagios.conf]/ensure: defined content as '{md5}dc3d75e89931071d6dd4f0a17815fdba'
	Notice: /Stage[main]/Nagios/File[/etc/apache2/conf-enabled/nagios.conf]/ensure: created
	Notice: Finished catalog run in 66.77 seconds

LÄPI MENI ILMAN VIRHEITÄ !

Mutta nagios-backup.tar.gz paketti ja apache2-mod-php7.0 paketti muutti tilaansa jokaisella ajokerralla.

	puppetagent6:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetagent6.local
	Info: Applying configuration version '1494437473'
	--leikattu
	Notice: /Stage[main]/Nagios/Exec[nagios-backup.tar.gz]/returns: usr/local/nagios/bin/
	--leikattu
	Notice: /Stage[main]/Nagios/Package[apache2-mod-php7.0]/ensure: ensure changed 'purged' to 'present'
	Notice: Finished catalog run in 1.58 seconds

Korjaus oli muuttaa init.pp:stä seuraavia kohtia.

	package { 'apache2-mod-php7.0': } -> package { 'libapache2-mod-php7.0': require => Package['apache2'] }
	(Markus Pyhäranta 2017.)
	 
Lisäsin myös eri resurssien väliin riippuvuuksia.

Huomasin toki lisää ongelmia.. apt source listaus EI ole aina ajantasalla koneissa, jotenka lisäsin init.pp alkuun vielä
exec käskyn, joka ajetaan aina aluksi. (Timjrobinson 2014.)

Myös apache2 herjasi auth_modin puuttumisesta, lisätty linkin luonti.

Tässä lopullinen init.pp, jolla ei ongelmia ollut.

	class nagios {
	
			# Run apt-get update before installing packages
			exec { 'apt-update':
					command => '/usr/bin/apt-get update',
			}

			# Set global package parameters
			Package { ensure => 'installed',
					allowcdrom => 'true',
			}

			# Install apache2, php and required libs
			package { 'wget': }
			package { 'build-essential': }
			package { 'apache2': }
			package { 'php': }
			package { 'libapache2-mod-php7.0': require => Package['apache2'] }
			package { 'php-gd': }
			package { 'libgd-dev': }
			package { 'unzip': }

			# Settings for service apache2
			# Fetching nagios virtualhost config file from master
			# Package apache2 needs to installed first
			file { '/etc/apache2/sites-available/010-nagioslocal.conf':
					ensure  => 'file',
					content => template('nagios/010-nagioslocal.erb'),
					require => Package['apache2'],
			}

			# Creating link from apache2 virtualhost sites-available to sites-enabled
			# Package apache2 needs to installed first
			file { '/etc/apache2/sites-enabled/010-nagioslocal.conf':
					ensure  => 'link',
					target  => '../sites-available/010-nagioslocal.conf',
					require => Package['apache2'],
			}

			# Fetching nagios.conf from master
			# Package apache2 needs to installed first
			file { '/etc/apache2/conf-available/nagios.conf':
					ensure  => 'file',
					content => template('nagios/nagios_conf.erb'),
					require => Package['apache2'],
			}

			# Creating link from apache2 nagios.conf conf-available to conf-enabled
			# Package apache2 needs to installed first
			# Notifying service nagios for changes
			file { '/etc/apache2/conf-enabled/nagios.conf':
					ensure  => 'link',
					target  => '../conf-available/nagios.conf',
					require => Package['apache2'],
					notify  => Service['nagios'],
			}

			# Fetching fqdn.conf from master
			# Package apache2 needs to installed first
			file { '/etc/apache2/conf-available/fqdn.conf':
					ensure  => 'file',
					content => template('nagios/fqdn_conf.erb'),
					require => Package['apache2'],
			}

			# Creating link from apache2 fqdn.conf conf-available to conf-enabled
			# Package apache2 needs to installed first
			file { '/etc/apache2/conf-enabled/fqdn.conf':
					ensure  => 'link',
					target  => '../conf-available/fqdn.conf',
					require => Package['apache2'],
			}

			# Fetching apache2.conf from master
			# Package apache2 needs to installed first
			# Notifying service apache2 for changes
			file { '/etc/apache2/apache2.conf':
					ensure  => 'file',
					replace => 'true',
					content => template('nagios/apache2_conf.erb'),
					notify  => Service['apache2'],
					require => Package['apache2'],
			}

			# Creating link from apache2 auth_digest mods-available to mods-enabled
			# Package apache2 needs to installed first
			file { '/etc/apache2/mods-enabled/auth_digest.load':
                ensure  => 'link',
                target  => '../mods-available/auth_digest.load',
                require => Package['apache2'],
			}

			# Changing apache2 to start automatically during bootup
			# Applied after Package apache2 is installed
			service { 'apache2':
					enable    => 'true',
					ensure    => 'running',
	#               provider  => 'systemd',
					require   => Package['apache2'],
			}

			# Creating group and user for nagios
			group { 'nagcmd': ensure => 'present' }
			group { 'nagios': ensure => 'present' }

			user { 'nagios':
					ensure  => 'present',
					gid     => '1001',
					uid     => '1001',
					groups  => [nagcmd, www-data],
					shell   => '/usr/sbin/nologin',
					comment => 'Nagios daemon user',
			}

			user { 'www-data':
					groups => [nagios,nagcmd],
			}

			# Fetch tarbals and nagiosDaemon
			# Package apache2 needs to installed first
			file { '/tmp/nagios-backup.tar.gz':
					ensure  => 'file',
					source  => 'puppet:///modules/nagios/nagios-backup.tar.gz',
					require => Package['apache2'],
			}

			# Fetching nagios daemon binary from maste
			# Package apache2 needs to installed firstr
			file { '/etc/init.d/nagios':
					ensure  => 'file',
					mode    => '0755',
					owner   => 'root',
					group   => 'root',
					source  => 'puppet:///modules/nagios/nagiosD',
					require => Package['apache2'],
			}

			# Unpacking nagios tarbal only if source changes
			exec { 'nagios-backup.tar.gz':
					path        => ['/bin', '/usr/bin', '/usr/lib'],
					cwd         => '/tmp',
					command     => 'tar xvpfz nagios-backup.tar.gz --overwrite -C /',
	#               onlyif      => 'test -f nagios-backup.tar.gz && test -f /etc/init.d/apache2',
					subscribe   => File['/tmp/nagios-backup.tar.gz'],
					refreshonly => 'true',
			}

			# Put nagios to service only if source changes
			exec {'update_rcd':
					path        => ['/bin', '/usr/bin', '/usr/lib', '/usr/sbin'],
					command     => 'update-rc.d nagios defaults',
	#               onlyif      => 'test -f /etc/init.d/nagios',
					subscribe   => File['/etc/init.d/nagios'],
					refreshonly => 'true',
			}

			# Changing nagios to start automatically during bootup
			# Apache2 package required before doing anything
			service { 'nagios':
					enable    => 'true',
					ensure    => 'running',
	#               provider  => 'systemd',
					require   => Package['apache2'],
			}

	}


# Lähteet

Askubuntu 2012. Copy files without losing file/folder permissions. 
Luettavissa: https://askubuntu.com/questions/225865/copy-files-without-losing-file-folder-permissions. Luettu: 10.5.2017.

Stack overflow 2013. How to uncompress a tar.gz in another directory.
Luettavissa: http://stackoverflow.com/questions/18402395/how-to-uncompress-a-tar-gz-in-another-directory. Luettu: 10.5.2017.

Bitfield Consulting 2010. Puppet and MySQL: create databases and users.
Luettavissa: http://bitfieldconsulting.com/puppet-and-mysql-create-databases-and-users. Luettu: 3.5.2017.

DigitalOcean 2017. How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 16.04 Server.
Luettavissa: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server. Luettu: 9.5.2017.

Docker docs 2017. Dockerfile reference. Luettavissa: https://docs.docker.com/engine/reference/builder/. Luettu: 8.5.2017.

Linode 2016. Install LAMP on Ubuntu 16.04.
Luettavissa: https://www.linode.com/docs/web-servers/lamp/install-lamp-on-ubuntu-16-04. Luettu 3.5.2017.

Nagios 2017. Nagios - Installing Nagios Core from Source. 
Luettavissa: https://assets.nagios.com/downloads/nagioscore/docs/Installing_Nagios_Core_From_Source.pdf#_ga=2.238731145.863927744.1494269411-1872685986.1494269380. Luettu 8.5.2017.

Markus Pyhäranta 2017. Palvelinten hallinta – Korvaava tehtävä + vertaisarvioinnit.
Luettavissa: https://markuspyharanta.wordpress.com/2017/01/23/palvelinten-hallinta-korvaava-tehtava-vertaisarvioinnit/. Luettu: 10.5.2017. 

Puppet Cookbook 2015a. You want some resource examples.
Luettavissa: https://www.puppetcookbook.com/posts/show-resources-with-ralsh.html. Luettu 3.5.2017.

Puppet CookBook 2015b. Selective exec running.
Luettavissa: https://www.puppetcookbook.com/posts/exec-onlyif.html. Luettu: 10.5.2017.

Puppet Documentation a. Module Fundamental.
Luettavissa: https://docs.puppet.com/puppet/3.8/modules_fundamentals.html#files. Luettu: 10.5.2017.

Puppet Documentation b. Resource Type: exec.
Luettavissa: https://docs.puppet.com/puppet/3.8/types/exec.html#exec-attribute-unless. Luettu: 10.5.2017.

Superuser 2012. Install a source package with puppet.
Luettavissa: https://superuser.com/questions/415047/install-a-source-package-with-puppet. Luettu 3.5.2017.

Timjrobinson 2014. Puppet how to force apt-get update. Luettavissa: http://timjrobinson.com/puppet-how-to-force-apt-get-update/. Luettu: 10.5.2017.

---
Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com