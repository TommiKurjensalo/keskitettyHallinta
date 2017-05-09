class hello {

	# Luodaan /tmp/helloModule tiedosto, jonka sisalla on teksti 'Hello World!'
	# Varmistetaan, etta checksum tyyppi on md5. 
	# Maaritetaan myos tiedoston oikeudet 0744 = u+rwx g+rwx o+r
	file { '/tmp/helloModule':
		content => "Hello World!\n",
		checksum => "md5",
		mode => "0774"
	}
}
