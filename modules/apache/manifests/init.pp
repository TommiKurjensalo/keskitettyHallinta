class apache {

	# Asennetaan paketti apache2, haluten tilan olevan installed
	package { "apache2":
		ensure => "installed",
		allowcdrom => true,
	}
	
	file { "/etc/hosts":
		ensure => "file",
		content => template('apache/hosts.erb'),
		notify => Service['apache2'],
	}

       file { "/etc/apache2/sites-available/001-kovaluu.com":
                ensure => "file",
                content => template('apache/001-kovaluu.com.erb'),
        }

	file { "/etc/apache2/sites-enabled/001-kovaluu.com":
		ensure => "link",
		target => "/etc/apache2/sites-available/001-kovaluu.com",
	}

	file { "/var/www/kovaluu.com":
		ensure => "directory",
	}

	file { "/var/www/kovaluu.com/index.html":
		ensure => "file",
		content => template('apache/index.html.erb'),
		notify => Service['apache2'],
	}

        # Varmistetaan, että palvelu on varmasti päällä ja käynnistyy automaattisesti
        service { "apache2":
                enable => "true",
                ensure => "running",
                require => Package["apache2"],
        }
}
