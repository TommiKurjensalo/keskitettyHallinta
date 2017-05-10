class apt-test {

        # Run apt-get update before installing packages
        exec { 'apt-update':
		path => ['/usr/bin'],
                command => '/usr/bin/apt-get update',
                onlyif => 'find /var/lib/apt/lists -maxdepth 2 -mtime -1 -type f -name *ubuntu* 2> /dev/null',
        }

	# Luodaan /tmp/welcome tiedosto, jonka sisalla on teksti 'Hello World from hostname!'
	# Maaritetaan myos tiedoston oikeudet 0744 = u+rwx g+rwx o+r
	file { '/tmp/apt-test':
		content => "Hello World from $hostname!\n",
		mode => "0774",
	}
}
