#  Package-File-Server. Asenna ja konfiguroi jokin demoni package-file-server -tyyliin.

-- koneen tiedot

Päätin asentaa apachen palvelun ja luoda sille virtuaalihostin. Luonnollisesti uusi sivu tarvitsee oman konfigurointi tiedostonsa ja myös uuden etusivun.

## Alkutoimenpiteet

Homma lähti perinteisesti luomalla uuden moduulin ja kansiot

    $ mkdir -P /etc/puppet/modules/apache/{manifests,templates}

Sitten asensin apachen, jotta sain sopivat pohja configit ja pääsin testaamaan toimivuutta ennen modullin lopullista versiota.

    $ sudo apt-get update && sudo apt-get install -y apache2

Kopioin 001-default.conf tiedoston uudelle nimelle

HUOM ! Aluksi tein virheellisesti tiedoston, joka oli nimeltään 001-kovaluu.com.conf ja tämähän ei tietenkään toimi, koska pääte ei ole pelkkä .conf.

    user@linux:/etc/apache2/sites-available$ sudo cp 000-default.conf 001-kovaluucom.conf

## Apache sivujen muokkausta

Muokkasin uutta config tiedostoa. Alla vain rivit mitä muutin.

    user@linux:/etc/apache2/sites-available$ sudoedit 001-kovaluucom.conf
    
    ServerName www.kovaluu.com
	  ServerAlias kovaluu.com

	  ServerAdmin admin@kovaluu.com
	  DocumentRoot /var/www/kovaluu.com

	  ErrorLog ${APACHE_LOG_DIR}/error_kovaluu.log
	  CustomLog ${APACHE_LOG_DIR}/access_kovaluu.log combined
    
## Linkkien tekoa sites-available -> sites-enabled

    $ sudo ln -s 001-kovaluucom.conf ../sites-available/001-kovaluucom.conf 
    ln: failed to create symbolic link '../sites-available/001-kovaluucom.conf': File exists
    /etc/apache2/sites-available
    
    $ sudo ln -s ../sites-available/001-kovaluucom.conf 001-kovaluucom.conf 
    ln: failed to create symbolic link '001-kovaluucom.conf': File exists
    /etc/apache2/sites-available
    
    $ sudo ln -s ../sites-enabled/001-kovaluucom.conf 001-kovaluucom.conf 
    ln: failed to create symbolic link '001-kovaluucom.conf': File exists
    /etc/apache2/sites-available
    
    JNE ..
    
Ja kun tarpeeksi montakertaa yrittää, niin löytyyhän se oikea syntaxi

    user@linux:/etc/apache2/sites-available$ sudo ln -s ../sites-available/001-kovaluucom.conf ../sites-enabled/001-kovaluucom.conf

    
    user@linux:/etc/apache2/sites-available $ ls -l ../sites-enabled/
    total 0
    lrwxrwxrwx 1 root root 35 huhti 18 19:57 000-default.conf -> ../sites-available/000-default.conf
    lrwxrwxrwx 1 root root 19 huhti 18 20:13 001-kovaluucom.conf -> ../sites-available/001-kovaluucom.conf

    
## Uuden etusivun tekoa virtuaalihostille

    $ sudo mkdir /var/www/kovaluu.com
    $ sudoedit /var/www/kovaluu.com/index.html 
    
      <!doctype html>
      <html>
      <head>
        <title>www.kovaluu.com</title>
        <meta charset="utf-8" />
      </head>
      <body>
        <h1>www.kovaluu.com</h1>
        <p>Terve, maailma! Tämä on Apachen nimipohjainen "virtuaalipalvelin"</p>
      </body>
      </html>

## Apache palvelun uudelleenkäynnistys

	$ sudo service apache2 restart
	
	
## Uuden sivun testausta

	$ curl -n www.kovaluu.com
	<!doctype html>
	<html>
	<head>
		<title>www.kovaluu.com</title>
		<meta charset="utf-8" />
	</head>
	<body>
		<h1>www.kovaluu.com</h1>
		<p>Terve, maailma! Tämä on Apachen nimipohjainen "virtuaalipalvelin"</p>
	</body>
	</html>

# Puppet modulin tekoa

Kopioin index.html ja sivun config tiedoston mallikappaleiksi.

	$ cp /var/www/kovaluu.com/index.html /etc/puppet/modules/apache/templates/index.html.erb
	$ cp /etc/apache2/sites-available/001-kovaluucom.conf /etc/puppet/modules/apache/templates/001-kovaluucom.conf.erb
	
	
## init.pp luontia

	$ sudoedit /etc/puppet/modules/apache/manifests/init.pp
	class apache {

		# Asennetaan paketti apache2, haluten tilan olevan installed
		package { "apache2":
			ensure => "installed",
			allowcdrom => true,
		}

		# Kopioidaan apache2 kansioon uusi virtuaalihosti
	       file { "/etc/apache2/sites-available/001-kovaluucom.conf":
			ensure => "file",
			content => template('apache/001-kovaluucom.erb'),
		}

		# Luodaan linkki apache2 sites-available -> sites-enabled
		file { "/etc/apache2/sites-enabled/001-kovaluucom.conf":
			ensure => "link",
			target => "/etc/apache2/sites-available/001-kovaluucom.conf",
		}

		# Luodaan virtuaalihostille uusi kansio
		file { "/var/www/kovaluu.com":
			ensure => "directory",
		}

		# Kopioidaan virtuaalihostille uusi index.html
		file { "/var/www/kovaluu.com/index.html":
			ensure => "file",
			content => template('apache/index.html.erb'),
			notify => Service['apache2'],
		}

		# Varmistetaan, että palvelu on varmasti päällä ja käynnistyy automaattsesti
		service { "apache2":
			enable => "true",
			ensure => "running",
			require => Package["apache2"],
		}
    	}
	
Ongelmiakin toki oli, hetken aikaa sai taas testata tuota linkin tekoa. En tiedä mikä siinä on aina niin vaikeaa, että oikean syntaxin löytymisen kanssa saa hetken leikkiä. Mutta heti file { jälkeen tulee KOHDE ja target kohtaan tulee LÄHDE.

Kun uusi etusivu on kopioitu, käynnistetään apache2 palvelu uusiksi, jotta uusi virtuaalihost conf latautuu.

## Testausta

Poistetaan apache hilut taustalta.

	$ sudo apt-get remove -y apache2
	$ sudo rm -rf /etc/apache2/
	
Ajetaan puppet moduuli

	$ apuppet apache
	Notice: Compiled catalog for lag-vm in environment production in 1.51 seconds
	Error: Parameter path failed on File[../sites-enabled/001-kovaluucom.conf]: File paths must be fully qualified, not 		'../sites-enabled/001-kovaluucom.conf' at /etc/puppet/modules/apache/manifests/init.pp:16

Ei nähtävästi tehdä tällä tavalla, vaan koko linkki pitää olla kerrottuna. Tehdään siis testimuutos

	$ sudoedit /etc/puppet/modules/apache/manifests/init.pp
	
	<otettu oikea kohta>
	
		# Luodaan linkki apache2 sites-available -> sites-enabled
		file { "/etc/apache2/sites-enabled/001-kovaluucom.conf":
			ensure => "link",
			target => "../sites-available/001-kovaluucom.conf",
		}
	</otettu oikea kohta>

Uusi yritys ja, vóil....han kökkö..

Nyt meni linkin teko läpi, mutta sitten tuli uusia virheitä.

	Notice: Compiled catalog for lag-vm in environment production in 1.50 seconds
	Notice: /Stage[main]/Apache/Package[apache2]/ensure: created
	Notice: /Stage[main]/Apache/File[/etc/apache2/sites-available/001-kovaluucom.conf]/ensure: defined content as '{md5}8538f53963abb0bdac2871300db9124e'
	Notice: /Stage[main]/Apache/File[/etc/apache2/sites-enabled/001-kovaluucom.conf]/ensure: created
	Error: Could not start Service[apache2]: Execution of '/bin/systemctl start apache2' returned 1: Job for apache2.service failed because the control process exited with error code.
	See "systemctl status apache2.service" and "journalctl -xe" for details.
	Error: /Stage[main]/Apache/Service[apache2]/ensure: change from stopped to running failed: Could not start Service[apache2]: Execution of '/bin/systemctl start apache2' returned 1: Job for apache2.service failed because the control process exited with error code.
	See "systemctl status apache2.service" and "journalctl -xe" for details.

Tunnillahan tästä puhuttiin ja hetken aikaa googlailtuani löysin oikean kohdan, joka on service resurssin provider attribuutti

testasin niin systemd kuin debian vaihtoehtoa, mutta siltikin tuli herjaa, tosin herja hiukan muuttui. (Resource Type: service 2017.)

	Error: Could not start Service[apache2]: Execution of '/etc/init.d/apache2 start' returned 1: /etc/init.d/apache2: 46: .: Can't open /etc/apache2/envvars
	Starting apache2 (via systemctl): apache2.serviceJob for apache2.service failed because the control process exited with error code.
	See "systemctl status apache2.service" and "journalctl -xe" for details.
	 failed!
	Error: /Stage[main]/Apache/Service[apache2]/ensure: change from stopped to running failed: Could not start Service[apache2]: Execution of '/etc/init.d/apache2 start' returned 1: /etc/init.d/apache2: 46: .: Can't open /etc/apache2/envvars
	Starting apache2 (via systemctl): apache2.serviceJob for apache2.service failed because the control process exited with error code.
	See "systemctl status apache2.service" and "journalctl -xe" for details.
	 failed!




Resource Type: service 2017. Luettavissa: https://docs.puppet.com/puppet/latest/types/service.html#service-attribute-provider. Luettu 18.4.2017.

puppet service enable broken on ubuntu vivid with debian provider 2015.Luettavissa: https://bugs.launchpad.net/ubuntu/+source/puppet/+bug/1495853. Luettu 18.4.2017.



