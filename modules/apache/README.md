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
