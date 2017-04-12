class sshd {

	# Asennetaan paketti sshd, haluten tilan olevan installed
	package { "openssh-server":
		ensure => "installed",
		allowcdrom => true,
	}
	
	file { "/etc/ssh/sshd_config":
		ensure => "file",
		content => template('sshd/sshd_config.erb'),
		notify => Service['ssh'],
	}

        # Varmistetaan, että palvelu on varmasti päällä ja käynnistyy automaattisesti
        service { "ssh":
                enable => "true",
                ensure => "running",
                require => Package["openssh-server"],
        }
}
