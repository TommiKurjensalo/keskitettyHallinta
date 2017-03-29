class hello {
	file { '/tmp/helloModule':
		content => "Hello World!\n",
		checksum => "sha256",
		mode => "0774"
	}
}
