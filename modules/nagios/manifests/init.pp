class nagios {

	# Run apt-get update before installing packages
	exec { 'apt-update':
		command	    => '/usr/bin/apt-get update',
	}
		
	# Set global package parameters
	Package { ensure => 'installed', 
		allowcdrom => 'true', 
	}
	
	# Install apache2, php and required libs
	package { 'wget': }
	package { 'build-essential': }
	package { 'apache2': }
	package { 'php': }
	package { 'libapache2-mod-php7.0': require => Package['apache2'] }
	package { 'php-gd': }
	package { 'libgd-dev': }
	package { 'unzip': }	

	# Settings for service apache2
	# Fetching nagios virtualhost config file from master
	# Package apache2 needs to installed first
	file { '/etc/apache2/sites-available/010-nagioslocal.conf':
		ensure	=> 'file',
		content	=> template('nagios/010-nagioslocal.erb'),
		require => Package['apache2'],
	}

	# Creating link from apache2 virtualhost sites-available to sites-enabled
	# Package apache2 needs to installed first
	file { '/etc/apache2/sites-enabled/010-nagioslocal.conf':
		ensure	=> 'link',
		target	=> '../sites-available/010-nagioslocal.conf',
		require => Package['apache2'],
	}

	# Fetching nagios.conf from master
	# Package apache2 needs to installed first
	file { '/etc/apache2/conf-available/nagios.conf':
                ensure  => 'file',
                content => template('nagios/nagios_conf.erb'),
                require => Package['apache2'],
        }

        # Creating link from apache2 nagios.conf conf-available to conf-enabled
	# Package apache2 needs to installed first
	# Notifying service nagios for changes
        file { '/etc/apache2/conf-enabled/nagios.conf':
                ensure  => 'link',
                target  => '../conf-available/nagios.conf',
                require => Package['apache2'],
		notify	=> Service['nagios'],
        }

	# Fetching fqdn.conf from master
	# Package apache2 needs to installed first
        file { '/etc/apache2/conf-available/fqdn.conf':
                ensure  => 'file',
                content => template('nagios/fqdn_conf.erb'),
                require => Package['apache2'],
        }

        # Creating link from apache2 fqdn.conf conf-available to conf-enabled
	# Package apache2 needs to installed first
        file { '/etc/apache2/conf-enabled/fqdn.conf':
                ensure  => 'link',
                target  => '../conf-available/fqdn.conf',
                require => Package['apache2'],
        }

	# Fetching apache2.conf from master
	# Package apache2 needs to installed first
	# Notifying service apache2 for changes
        file { '/etc/apache2/apache2.conf':
                ensure  => 'file',
		replace	=> 'true',
                content => template('nagios/apache2_conf.erb'),
                notify  => Service['apache2'],
                require => Package['apache2'],
        }

	# Creating link from apache2 auth_digest mods-available to mods-enabled
        # Package apache2 needs to installed first
        file { '/etc/apache2/mods-enabled/auth_digest.load':
                ensure  => 'link',
                target  => '../mods-available/auth_digest.load',
                require => Package['apache2'],
        }
	
	# Changing apache2 to start automatically during bootup
	# Applied after Package apache2 is installed
	service { 'apache2':
		enable	  => 'true',
		ensure	  => 'running',
#		provider  => 'systemd',
		require	  => Package['apache2'],
	}

	# Creating group and user for nagios
	group { 'nagcmd': ensure => 'present' }
	group { 'nagios': ensure => 'present' }
	
	user { 'nagios': 
		ensure	=> 'present', 
		gid	=> '1001',
		uid	=> '1001',
		groups	=> [nagcmd, www-data], 
		shell	=> '/usr/sbin/nologin',
		comment => 'Nagios daemon user',
	}

	user { 'www-data':
		groups => [nagios,nagcmd],
	}

	# Fetch tarbals and nagiosDaemon
	# Package apache2 needs to installed first
	file { '/tmp/nagios-backup.tar.gz':
		ensure	=> 'file',
		source	=> 'puppet:///modules/nagios/nagios-backup.tar.gz',
		require => Package['apache2'],
	}

	# Fetching nagios daemon binary from maste
	# Package apache2 needs to installed firstr
	file { '/etc/init.d/nagios':
		ensure  => 'file',
		mode	=> '0755',
		owner	=> 'root',
		group	=> 'root',
                source	=> 'puppet:///modules/nagios/nagiosD',
		require => Package['apache2'],
        }

	# Unpacking nagios tarbal only if source changes
	exec { 'nagios-backup.tar.gz':
		path	    => ['/bin', '/usr/bin', '/usr/lib'],
		cwd	    => '/tmp',
		command	    => 'tar xvpfz nagios-backup.tar.gz --overwrite -C /',
#		onlyif	    => 'test -f nagios-backup.tar.gz && test -f /etc/init.d/apache2',
		subscribe   => File['/tmp/nagios-backup.tar.gz'],
		refreshonly => 'true',
	}

        # Put nagios to service only if source changes 
        exec {'update_rcd':
                path	    => ['/bin', '/usr/bin', '/usr/lib', '/usr/sbin'],
                command	    => 'update-rc.d nagios defaults',
#               onlyif	    => 'test -f /etc/init.d/nagios',
		subscribe   => File['/etc/init.d/nagios'],
		refreshonly => 'true',
        }

        # Changing nagios to start automatically during bootup
	# Apache2 package required before doing anything
        service { 'nagios':
                enable	  => 'true',
                ensure	  => 'running',
#               provider  => 'systemd',
		require	  => Package['apache2'],
        }

}

