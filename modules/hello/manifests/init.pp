class hello {

	# Luodaan /tmp/helloModule tiedosto, jonka sisällä on teksti 'Hello World!'
	# Varmistetaan, että checksum tyyppi on md5. 
	# Määritetään myös tiedoston oikeudet 0744 = u+rwx g+rwx o+r
	file { '/tmp/helloModule':
		content => "Hello World!\n",
		checksum => "md5",
		mode => "0774"
	}
}
