class git {

	# Haetaan paketti git ja asennetaan se.
	package { git:
		ensure => "installed",
	}

	# Kopioidaan globaalit git asetukset /etc/gitconfig tiedostoon
	file { "/etc/gitconfig":
		ensure => "file",
		content => template('git/gitconfig.erb'),
	}

}
