class sshd {

	# Asennetaan paketti sshd, haluten tilan olevan installed
	package { 'openssh-server':
	ensure => 'installed',
	}

	file { '/etc/ssh/sshd_config':
		ensure => 'file',
		content => 'template('sshd/sshd_config.erb'),
	}

	exec { 'restart_sshd_service'
		command => 'systemctl restart ssh',
	}

}

