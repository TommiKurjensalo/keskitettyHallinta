class ktehtava1 {

	# Asennetaan paketti screen ja varmistetään, että se tulee asennetuksi.
	# allowcdrom attribuutti vaaditaan liveUSB käytössä.
	package { 'screen':
		ensure => "installed",
		allowcdrom => "true"
	}

	# Luodaan timestamp muuttuja, jolle annetaan arvo date käskyä hyödyntäen.
	# Timestampin ulkoasu on muotoa yyyymmdd_hh:mm:ss
	$timestamp = generate('/bin/date', '+%Y%m%d_%H:%M:%S')

	# Luodaan tiedosto /tmp/ktehtava1, tarkistetaan onko tiedosto jo olemassa.
	# Sisältöön lisätään Timestamp: yyyymmdd_hh:mm:ss
	# Jos tiedosto on jo olemassa, tehdään siitä backup muotoon ktehtava1.puppet-bak
	file { '/tmp/ktehtava1':
		ensure => "present",
		content => "Timestamp: ${timestamp}",
		backup => "true"
	}
}
