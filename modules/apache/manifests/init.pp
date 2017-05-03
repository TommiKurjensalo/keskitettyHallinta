class apache {

	# Asennetaan paketti apache2, haluten tilan olevan installed
	package { 'apache2':
		ensure => 'installed',
		allowcdrom => 'true',
	}

	# Kopioidaan apache2 kansioon uusi virtuaalihosti
       file { '/etc/apache2/sites-available/001-kovaluucom.conf':
                ensure => 'file',
                content => template('apache/001-kovaluucom.erb'),
        }

	# Luodaan linkki apache2 sites-available -> sites-enabled
	file { '/etc/apache2/sites-enabled/001-kovaluucom.conf':
		ensure => 'link',
		target => '../sites-available/001-kovaluucom.conf',
		notify => Service['apache2'],
	}

	# Luodaan virtuaalihostille uusi kansio
	file { '/var/www/kovaluu.com':
		ensure => 'directory',
	}

	# Kopioidaan virtuaalihostille uusi index.html
	file { '/var/www/kovaluu.com/index.html':
		ensure => 'file',
		mode => '0644',
		content => template('apache/index.html.erb'),
		notify => Service['apache2'],
	}

        # Varmistetaan, että palvelu on varmasti päällä ja käynnistyy automaattisesti
        service { 'apache2':
                enable => 'true',
                ensure => 'running',
		provider => 'systemd',
                require => Package['apache2'],
        }
}
