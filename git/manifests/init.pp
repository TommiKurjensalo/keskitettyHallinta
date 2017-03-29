class git {

	package { git:
		ensure => "installed",
	}

	file { "/home/insp/.gitconfig":
		ensure => "file",
		replace => "true",
		purge => "true",
		mode => "0644",
		owner => "insp",
		group => "insp",
		source => "file:///etc/puppet/modules/git/files/git_config",
	}

}
