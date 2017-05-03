class nagios {

	# Set global package parameters
	Package { ensure => 'installed', allowcdrom => 'true' }
	
	# Install apache2, php7.0 and required libs
	package { 'apache2': }
	package { 'php7.0': }
	package { 'php-pear': }
	package { 'apache2-mod-php7.0': }
	package { 'php7.0-gd': }

	# Setting service apache2
	
	# Kopioidaan apache2 kansioon uusi virtuaalihosti
       	file { '/etc/apache2/sites-available/001-nagioslocal.conf':
                ensure => 'file',
                content => template('apache/001-nagioslocal.erb'),
        }

	# Luodaan linkki apache2 sites-available -> sites-enabled
	file { '/etc/apache2/sites-enabled/001-nagioslocal.conf':
		ensure => 'link',
		target => '../sites-available/001-nagioslocal.conf',
		notify => Service['apache2'],
	}

	# Luodaan virtuaalihostille uusi kansio
	file { '/var/www/nagios.local':
		ensure => 'directory',
	}

        # Varmistetaan, että palvelu on varmasti päällä ja käynnistyy automaattisesti
        service { 'apache2':
                enable => 'true',
                ensure => 'running',
		provider => 'systemd',
                require => Package['apache2'],
        }

	# Creating group and user for nagios
 	group { 'nagcmd': ensure => 'present' }
	
	user { 'nagios': 
		ensure => 'present', 
		password => 'Nagios123', 
		groups => [nagcmd, www-data], 
		shell => '/usr/sbin/nologin',
		comment => 'Nagios daemon user'
	}

	# Installing nagios
	
	netinstall { 'postgis':
  		url => 'http://postgis.refractions.net/download/postgis-1.5.5.tar.gz',
		extracted_dir => 'postgis-1.5.5',
		destination_dir => '/tmp',
		postextract_command => '/tmp/postgis-1.5.5/configure && make && sudo make install'
}


	# Settings for nagios
}
