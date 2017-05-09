class welcome {

	# Luodaan /tmp/welcome tiedosto, jonka sisalla on teksti 'Hello World from hostname!'
	# Maaritetaan myos tiedoston oikeudet 0744 = u+rwx g+rwx o+r
	file { '/tmp/welcome':
		content => "Hello World from $hostname!\n",
		mode => "0774",
	}
}
