class hello {
	file { '/tmp/helloModule':
		content => "Hello World!\n",
		checksum => "md5",
		mode => "0774"
	}
}
