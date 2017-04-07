class sshd {

	# Asennetaan paketti sshd, haluten tilan olevan installed
	package { "openssh-server":
		ensure => "installed",
	}

        # Varmistetaan, että palvelu on varmasti päällä ja käynnistyy automaattisesti
        service { "sshd":
                enable => "true",
                ensure => "running",
                require => Package["openssh-server"],
        }

	# Määritetään sshd_config tiedostoon muutama tärkeä asetus
	augeas { "sshd_config":
		context => "/files/etc/ssh/sshd_config",
		changes => [ 	"set PasswordAuthentication yes",
				"set UsePAM yes",
				"set PermitRootLogin no",
			   ],
		require => Package["openssh-server"],
		notify => Service["sshd"],
	}
}
