class git {

	# Haetaan paketti git ja asennetaan se.
	package { git:
		ensure => "installed",
	}

	# Määritetään käyttäjänimi $username muuttujalle
	$username = "insp"
	
	# Kopioidaan halutun käyttäjän kotihakemiston .gitconfig määrittelytiedosto
	# Muutetaan tiedoston oikeudet samalle käyttäjälle
	file { "/home/${username}/.gitconfig":
		ensure => "file",
		replace => "true",
		purge => "true",
		mode => "0644",
		owner => "$username",
		group => "$username",
		source => "file:///etc/puppet/modules/git/files/git_config",
	}

}
