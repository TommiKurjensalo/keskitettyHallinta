# Puppet Master-slave luominen ja testaaminen

# Puppet versio 3

Käytin alustana ubuntu 16.04.2 kontteja, jotka olen luonnut Docker for Windows versio 17.03.1-ce.

Loin yhden puppetmaster koneen, jonka nimi on puppetmaster. Agenttien koneet on muotoa puppetagent1, puppetagent2...puppetagent10 asti.

## PuppetMaster

Varmistin, että puppet* palvelut on alhaalla.

	$ sudo service --status-all |grep puppet
	[sudo] password for insp:
	 [ ? ]  hwclock.sh
	 [ ? ]  ondemand
	 [ - ]  puppet
	 [ - ]  puppetmaster
	 [ + ]  puppetqd

Lisäsin [] lohkojen alle kyseiset rivit /etc/puppet/puppet.conf

	[master]
	dns_alt_names = puppet puppetmaster puppetmaster.local
	
	[agent]
	server = puppetmaster.local

[agent] lohko on ns. turha, mutta se on lokaaleja testauksia varten.

Varmistin, että /etc/hosts tiedostossa on myös puppetmaster.local ja agentit.

	$ cat /etc/hosts
	#/etc/hosts
	127.0.0.1       localhost
	::1     localhost ip6-localhost ip6-loopback
	fe00::0 ip6-localnet
	ff00::0 ip6-mcastprefix
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
	172.17.0.3      puppetagent1 puppetagent1.local
	172.17.0.4      puppetagent2 puppetagent2.local
	172.17.0.5      puppetagent3 puppetagent3.local
	172.17.0.6      puppetagent4 puppetagent4.local
	172.17.0.7      puppetagent5 puppetagent5.local
	172.17.0.8      puppetagent6 puppetagent6.local
	172.17.0.9      puppetagent7 puppetagent7.local
	172.17.0.10     puppetagent8 puppetagent8.local
	172.17.0.11     puppetagent9 puppetagent9.local
	172.17.0.12     puppetagent10 puppetagent10.local
	172.17.0.2      puppetmaster puppetmaster.local


Käynnistin puppet* palvelut

	insp@puppetmaster:~$ sudo service puppet start
	 * Starting puppet agent								[ OK ]
	insp@puppetmaster:~$ sudo service puppetmaster start
	 * Starting puppet master								[ OK ]

Käynnistin puppet agentin
 
	$ sudo puppet agent --enable
	
Tein testiajon

	$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetmaster.local
	Info: Applying configuration version '1494325830'
	Notice: Finished catalog run in 0.03 seconds
	
Lisäsin welcome moduulin /etc/puppet/manifests/site.pp tiedostoon

Käytin apuna http://rubular.com/ preg match sivustoa, jolla tein nodemääritykset.

	#/etc/puppet/manifests/site.pp
	node ^puppetagent\d+\.local$ {
	include welcome
	}

	node puppetmaster.local {
	include welcome
	}

Jos on laiska ja haluaa vain tehdä testauksen mihin tahansa nodeen, niin tiedosto voi sisältää vain 1 rivin.

	#/etc/puppet/manifests/site.pp
	include welcome
	
Welcome moduulin sisältö

	$ cat /etc/puppet/modules/welcome/manifests/init.pp
	class welcome {

			# Luodaan /tmp/welcome tiedosto, jonka sisalla on teksti 'Hello World! from hostname'
			# Maaritetaan myos tiedoston oikeudet 0744 = u+rwx g+rwx o+r
			file { '/tmp/welcome':
					content => "Hello World from $hostname!\n",
					mode => "0774",
			}
	}

Nyt kun on lisätty jotain tehtäviä agenteille, tehdään testiajoja uudelleen.

Jonkun syyn takia puppetmaster.local haluaa väkisinkin etsiä tietoa puppetagent node lohkosta.

	insp@puppetmaster:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Error: Could not retrieve catalog from remote server: Error 400 on SERVER: Could not parse for environment production: Could not match ^puppetagent\d+\.local$ at /etc/puppet/manifests/site.pp:1 on node puppetmaster.local
	Warning: Not using cache on failed catalog
	Error: Could not retrieve catalog; skipping run

Poistetaan puppetagent node ja yritetään uudelleen.

	insp@puppetmaster:~$ sudo puppet agent --enable
	insp@puppetmaster:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetmaster.local
	Info: Applying configuration version '1494326687'
	Notice: /Stage[main]/Welcome/File[/tmp/welcome]/ensure: defined content as '{md5}7a8a7b6c90d1951d68aa76d238c2e22c'
	Notice: Finished catalog run in 0.07 seconds

	insp@puppetmaster:~$ cat /tmp/welcome
	Hello World from puppetmaster!

Nyt toimii..

Poistetaan welcome tiedosto

	insp@puppetmaster:~$ rm /tmp/welcome
	rm: remove write-protected regular file '/tmp/welcome'? y
	rm: cannot remove '/tmp/welcome': Operation not permitted
	insp@puppetmaster:~$ sudo rm /tmp/welcome

Lisätään puppetagent pregmatch lohko takaisin..

	insp@puppetmaster:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetmaster.local
	Info: Applying configuration version '1494326744'
	Notice: /Stage[main]/Welcome/File[/tmp/welcome]/ensure: defined content as '{md5}7a8a7b6c90d1951d68aa76d238c2e22c'
	Notice: Finished catalog run in 0.05 seconds

.. ja nyt toimii.. mystistä.

## Puppetagent

Otetaan ensimmäinen puppetagent1 kone mukaan.

Varmistetaan, että /etc/puppet/puppet.conf on kunnossa

	$ cat /etc/puppet/puppet.conf
	[main]
	logdir=/var/log/puppet
	vardir=/var/lib/puppet
	ssldir=/var/lib/puppet/ssl
	rundir=/run/puppet
	factpath=$vardir/lib/facter
	prerun_command=/etc/puppet/etckeeper-commit-pre
	postrun_command=/etc/puppet/etckeeper-commit-post

	[master]
	# These are needed when the puppetmaster is run by passenger
	# and can safely be removed if webrick is used.
	ssl_client_header = SSL_CLIENT_S_DN
	ssl_client_verify_header = SSL_CLIENT_VERIFY

	[agent]
	server = puppetmaster.local
	
Näissä konteissa (container) oli jo asetukset kunnossa, koska olen ne niin määritellyt..

Varmistetaan yhteys

	$ ping -c 2 puppetmaster.local
	PING puppetmaster (172.17.0.2) 56(84) bytes of data.
	64 bytes from puppetmaster (172.17.0.2): icmp_seq=1 ttl=64 time=0.052 ms
	64 bytes from puppetmaster (172.17.0.2): icmp_seq=2 ttl=64 time=0.048 ms

	--- puppetmaster ping statistics ---
	2 packets transmitted, 2 received, 0% packet loss, time 1041ms
	rtt min/avg/max/mdev = 0.048/0.050/0.052/0.002 ms

Myös hosts tiedostot on määritelty näissä kuntoon, nämä kannattaa muistaa mikäli DNS palvelua ei ole käytössä.

	$ cat /etc/hosts
	127.0.0.1       localhost
	::1     localhost ip6-localhost ip6-loopback
	fe00::0 ip6-localnet
	ff00::0 ip6-mcastprefix
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
	172.17.0.2      puppetmaster puppetmaster.local
	172.17.0.4      puppetagent1

Testataan

	$ sudo puppet agent -t
	Warning: Unable to fetch my node definition, but the agent run will continue:
	Warning: SSL_connect returned=1 errno=0 state=error: certificate verify failed: [self signed certificate in certificate chain for /CN=Puppet CA: puppetmaster.local]
	Info: Retrieving pluginfacts
	Error: /File[/var/lib/puppet/facts.d]: Failed to generate additional resources using 'eval_generate': SSL_connect returned=1 errno=0 state=error: certificate verify failed: [self signed certificate in certificate chain for /CN=Puppet CA: puppetmaster.local]
	Error: /File[/var/lib/puppet/facts.d]: Could not evaluate: Could not retrieve file metadata for puppet://puppetmaster.local/pluginfacts: SSL_connect returned=1 errno=0 state=error: certificate verify failed: [self signed certificate in certificate chain for /CN=Puppet CA: puppetmaster.local]
	Info: Retrieving plugin
	Error: /File[/var/lib/puppet/lib]: Failed to generate additional resources using 'eval_generate': SSL_connect returned=1 errno=0 state=error: certificate verify failed: [self signed certificate in certificate chain for /CN=Puppet CA: puppetmaster.local]
	Error: /File[/var/lib/puppet/lib]: Could not evaluate: Could not retrieve file metadata for puppet://puppetmaster.local/plugins: SSL_connect returned=1 errno=0 state=error: certificate verify failed: [self signed certificate in certificate chain for /CN=Puppet CA: puppetmaster.local]
	Error: Could not retrieve catalog from remote server: SSL_connect returned=1 errno=0 state=error: certificate verify failed: [self signed certificate in certificate chain for /CN=Puppet CA: puppetmaster.local]
	Warning: Not using cache on failed catalog
	Error: Could not retrieve catalog; skipping run
	Error: Could not send report: SSL_connect returned=1 errno=0 state=error: certificate verify failed: [self signed certificate in certificate chain for /CN=Puppet CA: puppetmaster.local]

Ongelmana oli se, että olin jo aiemmin testaillut master-agent toimivuuksia juurikin agent1 koneella.

Eli ei muutakuin poistamaan certit.

Sammutetaan ensin puppetagent
	
		$ sudo puppet agent --disable
		$ sudo rm -rf /var/lib/puppet/ssl
	
Agentti takaisin päälle

	$ sudo puppet agent --enable
	$ sudo service puppet start

	
Uusi yritys

	$ sudo puppet agent -t
	Info: Creating a new SSL key for puppetagent1.local
	Info: Caching certificate for ca
	Info: csr_attributes file loading from /etc/puppet/csr_attributes.yaml
	Info: Creating a new SSL certificate request for puppetagent1.local
	Info: Certificate Request fingerprint (SHA256): 86:87:3D:B5:C7:54:05:FA:BA:9D:5E:AB:1A:D2:01:66:4E:AD:68:2A:E4:D8:A7:6D:D5:8E:AD:34:C7:CD:85:F8
	Info: Caching certificate for ca
	Exiting; no certificate found and waitforcert is disabled

Nyt näyttää paremmalle.

Seuraavaksi tehdään cert sign käsky masterilla.

	insp@puppetmaster:~$ sudo puppet cert --list --all
	  "puppetagent1.local" (SHA256) 86:87:3D:B5:C7:54:05:FA:BA:9D:5E:AB:1A:D2:01:66:4E:AD:68:2A:E4:D8:A7:6D:D5:8E:AD:34:C7:CD:85:F8
	+ "puppetmaster.local" (SHA256) 8B:A8:8A:5A:09:CB:38:8A:75:31:60:06:82:AA:0F:18:06:3B:1E:FE:C0:2D:8A:E7:C7:FF:EB:FF:36:5B:1E:AE (alt names: "DNS:puppet puppetmaster puppetmaster.local", "DNS:puppetmaster.local")
	
	insp@puppetmaster:~$ sudo puppet cert sign puppetagent1.local
	Notice: Signed certificate request for puppetagent1.local
	Notice: Removing file Puppet::SSL::CertificateRequest puppetagent1.local at '/var/lib/puppet/ssl/ca/requests/puppetagent1.local.pem'

Nyt pitäisi mennä agentti kyselyn läpi kun sertifikaatti on hyväksytty.

	$ sudo puppet agent -t
	Info: Caching certificate for puppetagent1.local
	Info: Caching certificate_revocation_list for ca
	Info: Caching certificate for puppetagent1.local
	Warning: Unable to fetch my node definition, but the agent run will continue:
	Warning: undefined method `include?' for nil:NilClass
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetagent1.local
	Info: Applying configuration version '1494326744'
	Notice: Finished catalog run in 0.05 seconds

Ensimmäisellä kerralla ei löytänyt node kohtaisia määrityksiä, mutta toisella kerralla löysi.

	insp@puppetagent1:~$ sudo puppet agent -t
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetagent1.local
	Info: Applying configuration version '1494326744'
	Notice: Finished catalog run in 0.04 seconds
	
	insp@puppetagent1:~$ ls /tmp
	welcome
	
	insp@puppetagent1:~$ cat /tmp/welcome
	Hello World from puppetagent1!

Sama prosessi toistetaan agenteille 2-10.

Certtipyyntö

	agent$ sudo puppet agent -t

Hyväksyntä

	master$ sudo puppet cert sign puppetagent2.local
	
Agentit päälle

	$ sudo puppet agent --enable && sudo service puppet start
	$ sudo puppet agent -t
	
Lopputulos

	$ cat /tmp/welcome
	Hello World from puppetagent2!

Luodaan masterille /etc/puppet/autosign.conf, jonne määritellään nodet jotka saavat automaattisesti sertifikaattinsa hyväksytyksi.
Kopioidaan toimiva regexp rivi /etc/puppet/manifests/site.pp tiedostosta.

	puppetmaster$ cat /etc/puppet/autosign.conf
	/^puppetagent\d+\.local$/
	
	(The Linux Juggernaut 2014.)
	
Lisätään /etc/puppet/puppet.conf tiedostoon [master] lohkoon uusi rivi.

	puppetmaster$ cat /etc/puppet/puppet.conf
	[master]
	autosign = true

Käynnistetään palvelut uudelleen ja testataan puppetagent3 koneella toimivuutta.

	puppetmaster$ sudo service puppet restart && sudo service puppetmaster restart

Agentti päälle ja testausta

	$ sudo puppet agent --enable && sudo service puppet start
	$ sudo puppet agent -t && cat /tmp/welcome
	Info: Retrieving pluginfacts
	Info: Retrieving plugin
	Info: Caching catalog for puppetagent3.local
	Info: Applying configuration version '1494330760'
	Notice: Finished catalog run in 0.02 seconds
	Hello World from puppetagent3!

Puppetmasterilla

	$ sudo puppet cert --list --all
	+ "puppetagent1.local" (SHA256) AA:7D:48:E1:92:7E:A2:B2:2A:C9:46:B7:FE:13:5B:02:1E:FE:0F:FB:C5:E7:EF:23:9E:3C:76:9C:E1:F9:95:01
	+ "puppetagent2.local" (SHA256) FF:2B:23:8A:62:D2:E3:61:84:CD:1A:61:80:DD:54:5D:03:57:B0:E2:E0:FE:8E:79:19:5F:9B:C6:BC:22:28:60
	+ "puppetagent3.local" (SHA256) F5:DC:EA:BA:72:A3:4D:DB:BB:A5:BB:E2:D5:D2:C8:97:07:69:71:D3:AD:8B:08:73:BF:87:AF:58:46:52:A3:C8
	+ "puppetmaster.local" (SHA256) 8B:A8:8A:5A:09:CB:38:8A:75:31:60:06:82:AA:0F:18:06:3B:1E:FE:C0:2D:8A:E7:C7:FF:EB:FF:36:5B:1E:AE (alt names: "DNS:puppet puppetmaster puppetmaster.local", "DNS:puppetmaster.local")

Puppetagent3 on ilmestynyt onnistuneesti !

.. Tein nämä kaikki agenteille4-10.

Masterilla sertifikaatti listausta

puppetmaster:/etc/puppet$ sudo puppet cert --list --all
+ "puppetagent1.local"  (SHA256) AA:7D:48:E1:92:7E:A2:B2:2A:C9:46:B7:FE:13:5B:02:1E:FE:0F:FB:C5:E7:EF:23:9E:3C:76:9C:E1:F9:95:01
+ "puppetagent10.local" (SHA256) C4:F8:4E:24:91:0E:4F:25:6C:30:0D:4A:E1:88:6A:22:92:80:FD:6A:BF:07:65:E3:7F:E9:46:3F:0D:FE:80:FB
+ "puppetagent2.local"  (SHA256) FF:2B:23:8A:62:D2:E3:61:84:CD:1A:61:80:DD:54:5D:03:57:B0:E2:E0:FE:8E:79:19:5F:9B:C6:BC:22:28:60
+ "puppetagent3.local"  (SHA256) F5:DC:EA:BA:72:A3:4D:DB:BB:A5:BB:E2:D5:D2:C8:97:07:69:71:D3:AD:8B:08:73:BF:87:AF:58:46:52:A3:C8
+ "puppetagent4.local"  (SHA256) 3F:B0:0B:29:E4:42:B2:3B:8B:3E:B6:33:6F:DF:A4:BA:0E:C4:58:C0:00:BC:0C:A9:9A:58:C5:BB:8E:DE:D4:1E
+ "puppetagent5.local"  (SHA256) 1A:9D:6B:23:EC:28:40:44:84:A7:F9:EA:97:B6:BA:92:0F:74:15:C0:E3:CC:78:7C:B6:28:BE:A1:A6:D9:41:C7
+ "puppetagent6.local"  (SHA256) 0F:89:D8:54:D7:4D:13:CD:68:3F:CB:1C:76:81:E1:B8:3B:2E:66:B8:85:2E:4A:E6:98:E8:54:02:92:3D:FD:A7
+ "puppetagent7.local"  (SHA256) 7B:2A:EB:FC:31:C9:2F:78:81:79:D6:02:67:D0:C5:09:34:6D:CE:64:59:D9:1C:A4:71:05:A9:87:9E:8A:7E:E1
+ "puppetagent8.local"  (SHA256) 65:68:65:8B:C6:2B:CB:2D:F2:6A:0A:3B:06:D7:E3:DC:DF:B6:93:FC:E4:A2:C9:ED:DA:65:17:BA:83:3A:1F:EA
+ "puppetagent9.local"  (SHA256) 9F:50:2A:93:DB:06:31:AD:D6:96:56:20:41:D2:CC:67:C3:96:DB:C1:D5:4D:75:6D:BF:8F:9D:56:D3:67:BB:CE
+ "puppetmaster.local"  (SHA256) 8B:A8:8A:5A:09:CB:38:8A:75:31:60:06:82:AA:0F:18:06:3B:1E:FE:C0:2D:8A:E7:C7:FF:EB:FF:36:5B:1E:AE (alt names: "DNS:puppet puppetmaster puppetmaster.local", "DNS:puppetmaster.local")

Nyt kannattaa kommentoida ulos autosign = true rivi puppet.conf tiedostosta.
	
	
# Puppet versio 4 testailua
 
Käytin alustana [Oracle VM VirtualBox](https://www.virtualbox.org/) v5.1.18 virtuaaliympäristössä toimivaa [Xubuntu 16.10 32bit](http://se.archive.ubuntu.com/mirror/cdimage.ubuntu.com/xubuntu/releases/16.10/release/) versiota.

! HUOM, en saanut moduleita siirtymään master->slave välillä.
Aloittelin testailun noin 13 aikoihin ja lopettelin 24 aikoihin.

Puppet client ja master versio=4.5.2 ja ruby_version=2.3.1.

## Vagrantin asennus

      $ sudo apt-get install -y vagrant

Luodaan uusi kansio virtuaalikoneelle ja tehdään asetustiedosto.

      $ mkdir puppetSlave && touch puppetSlave/Vagrantfile

Asennetaan virtualbox

      $ sudo apt-get install -y virtualbox

Asennetaan virtuaalikoneen image

      $ vagrant box add precise32 http://files.vagrantup.com/precise32.box

Latauksessa kun nähtävästi kestää 3tuntia, niin käynnistän sitten toisen koneen liveusb tilassa.

## Puppet-masterin asennus

      $ sudo apt-get -y install puppetmaster

Timezone kuntoon, jotta puppet v4 toimisi oikein

      $ sudo timedatectl set-timezone Europe/Helsinki
      $ sudo timedatectl --adjust-system-clock set-local-rtc 1

Sammutin puppet-master palvelun, jotta voin tehdä asetusmuutoksia

      $ sudo puppet resource service puppet-master ensure=stopped
      $ sudoedit /etc/puppet/puppet.conf

# Määrittelyä

Puppet.conf sisältö muutoksien jälkeen. Lisäsin dns_alt_names perään koneen nimeni ja 
[agent] lohkon server tietoineen testausta varten.

    [main]
      ssldir = /var/lib/puppet/ssl
      basemodulepath = $confdir/modules:/etc/puppet/modules
   
      [master]
      vardir = /var/lib/puppet
      cadir  = /var/lib/puppet/ssl/ca
      dns_alt_names = puppet, lag-vm
   
      [agent]
      server = lag-vm

Palvelut takaisin päälle

    $ sudo puppet resource service puppet-master ensure=running
    $ sudo puppet resource service puppet-master enable=true

Sitten ajoin testauksia, jotta näen toimiiko koko master-agent systeemi

    $ sudo puppet agent -tdv

(Puppet Docs 2016c).


## Agent koneen luonti

Tein toisen virtuaalikoneen Oraclen VM VirtualBoxilla, käynnistin xubuntun liveusb tilassa.
Määrittelin verkkokortit bridged tilaan, jotta sain reitittimen dhcp:ltä ip-osoitteen. Näin ollen kummatkin koneet
näkevät toisensa ja pingi menee läpi.

## Puppetin asennus

      $ sudo apt-get update && sudo apt-get install -y puppet-agent

Lisätään palvelimen osoite puppet.conf tiedostoon

    $ sudoedit /etc/puppet/puppet.conf

       [agent]
      server = lag-vm

Palvelun sammutus ja uudelleen käynnistäminen

     $ sudo systemctl restart puppet-agent 
     
### Herjat

 Paikallinen puppet agent ei vain löydä konekohtaisia määrityksiä
 
      Warning: Unable to fetch my node definition, but the agent run will continue:
      Warning: Server hostname 'lag-vm.local' did not match server certificate; expected one of lag-vm, 
      DNS:lag-vm, DNS:puppet
 
 Tuli iso liuta valituksia certifikaatin epäyhteensopivuudesta, koska sitä ei ole vielä edes hyväksytty palvelimen puolelta.
 
      Error: /File[/var/cache/puppet/facts.d]: Failed to generate additional resources using 'eval_generate': 
      Server hostname 'lag-vm.local' did not match server certificate; expected one of lag-vm, DNS:lag-vm, DNS:puppet
      Error: /File[/var/cache/puppet/facts.d]: Could not evaluate: Could not retrieve file metadata for 
      puppet:///pluginfacts: Server hostname 'lag-vm.local' did not match server certificate; 
      expected one of lag-vm, DNS:lag-vm, DNS:puppet
      Error: /File[/var/cache/puppet/lib]: Failed to generate additional resources using 'eval_generate': 
      Server hostname 'lag-vm.local' did not match server certificate; expected one of lag-vm, DNS:lag-vm, DNS:puppet
      Error: /File[/var/cache/puppet/lib]: Could not evaluate: Could not retrieve file metadata for 
      puppet:///plugins: Server hostname 'lag-vm.local' did not match server certificate; 
      expected one of lag-vm, DNS:lag-vm, DNS:puppet
      Error: Could not retrieve catalog from remote server: Server hostname 'lag-vm.local' 
      did not match server certificate; expected one of lag-vm, DNS:lag-vm, DNS:puppet
      Warning: Not using cache on failed catalog
      Error: Could not retrieve catalog; skipping run
      Error: Could not send report: Server hostname 'lag-vm.local' did not match server certificate; 
      expected one of lag-vm, DNS:lag-vm, DNS:puppet

Mikään yllä olevista ei oikeasti ole haitallinan tässä testaushetkessä.

Luodaan määritystiedosto slave koneille

(en tiedä onko oikea hakemisto site.pp tiedostolle !)

      $ sudo mkdir /etc/puppet/manifests/
      $ sudoedit /etc/puppet/manifests/site.pp

site.pp sisältö

      node default {
       class { 'hello': }
      }

Tarkistetaan, että ei tullut virheitä

      $ puppet parser validate /etc/puppet/manifests/site.pp

Tämä määrittää, että kaikille koneille ajetaan moduuli nimeltään hello, joka luo /tmp/helloModule tiedoston.

(Puppet Docs 2017.)

## Sertifikaattien poisto palvelimelta

      $ sudo puppet resource service-master ensure=stopped
      $ sudo rm -r /var/lib/puppet/ssl

Luodaan CA sertifikaatti uudelleen

      $ sudo puppet cert list -a

 Pitäisi tulla ilmoitus ->
 Notice: Signed certificate request for ca 

Luodaan koneen sertifikaatti

-- Keskeytä käynnistys ctrl+c kun Notice: Starting Puppet master version <versio> rivi ilmestyy
      $ sudo puppet master --no-daemonize --verbose
 
         Info: Caching certificate for ca
         Info: Creating a new SSL key for lag-vm
         Info: csr_attributes file loading from /etc/puppet/csr_attributes.yaml
         Info: Creating a new SSL certificate request for lag-vm
         Info: Certificate Request fingerprint (SHA256):         BB:91:CB:E6:0D:E6:EA:35:C9:45:DD:27:3A:BC:91:14:7C:7E:0E:EC:FF:C9:80:46:9F:2F:70:32:9F:44:0B:20
         Notice: lag-vm has a waiting certificate request
         Notice: Signed certificate request for lag-vm
         Notice: Removing file Puppet::SSL::CertificateRequest lag-vm at '/var/lib/puppet/ssl/ca/requests/lag-vm.pem'
         Notice: Removing file Puppet::SSL::CertificateRequest lag-vm at '/var/lib/puppet/ssl/certificate_requests/lag-vm.pem'
         Warning: The WEBrick Puppet master server is deprecated and will be removed in a future release. Please use Puppet Server    instead. See http://links.puppetlabs.com/deprecate-rack-webrick-servers for more information.
         (at /usr/lib/ruby/vendor_ruby/puppet/application/master.rb:210:in `main')
         Notice: Starting Puppet master version 4.5.2

## Luodaan sertifikaatit agentille uudelleen

Sammutetaan puppet agent

      $ sudo puppet resource service puppet-agent ensure=stopped

Poistetaan sertifikaatit

      $ sudo rm -rf /var/lib/puppet/ssl 

Käynnistetään palvelu uudelleen

      $ sudo puppet resource service puppet-agent ensure=running
 
 Käynnistetään puppet masteri

      $ sudo puppet resource service puppet-master ensure=running

Agentti testausta uudelleen

      $ sudo puppet agent -tdv
      Exiting: Failed to retrieve certificate and waitforce is disabled

Poistin odottamassa olevan sertin, se kun oli jo hyväksytty

      $ sudo rm /var/lib/puppet/ssl/certificate_requests/xubuntu.pem

(The JML Continuum 2013.)

Sitten hyväksytään uusi sertti masterilta.

      $ sudo puppet cert list
      "xubuntu" (SHA256) 41:84:B9:3F:D0:04:10:90:39:32:8A:32:21:D8:4A:22:BA:70:16:22:90:20:18:F8:10:4B:F4:DD:BA:71:8D:6C

      $ sudo puppet cert sign xubuntu

Vanhat kunnon virheilmoitukset jäivät.

      $ sudo puppet agent -t --noop
      Error: Could not request certificate: Failed to open TCP connection to lag-vm:8140 (Connection refused - connect(2) for "lag-vm" port 8140).

Vaikka kyseinen portti on auki ja toiminnassa..

(Puppet Docs 2016a).

Ongelmat poistuivat tällä hetkeksi, mutta muutaman ajon jälkeen samat errorit jälleen esillä.

Ja hetken päästä taas toimi ilman virheitä! Mutta ei kuitenkaan moduulit lataudu palvelimelta.

Taitaa olla resurssi pulaa ja joku kansiopolku ei nyt osu kohdalleen

# Ongelmia

Palvelimen päässä oli herja /var/log/puppet/masterhttp.log

    [2017-05-02 20:44:54] ERROR OpenSSL::SSL::SSLError: SSL_accept returned=1 errno=0 state=error: certificate verify failed
       /usr/lib/ruby/vendor_ruby/puppet/network/http/webrick.rb:32:in `accept'
    /usr/lib/ruby/vendor_ruby/puppet/network/http/webrick.rb:32:in `block (2 levels) in listen'

Agentin päässä oli

    $ sudo puppet agent -t

    Warning: Unable to fetch my node definition, but the agent run will continue:
    Warning: SSL_connect returned=1 errno=0 state=unknown state: sslv3 alert certificate revoked
    Info: Retrieving pluginfacts
    Error: /File[/var/cache/puppet/facts.d]: Failed to generate additional resources using 'eval_generate': SSL_connect returned=1 errno=0 state=unknown state: sslv3 alert certificate revoked
    Error: /File[/var/cache/puppet/facts.d]: Could not evaluate: Could not retrieve file metadata for puppet:///pluginfacts: SSL_connect returned=1 errno=0 state=unknown state: sslv3 alert certificate revoked
    Info: Retrieving plugin
    Error: /File[/var/cache/puppet/lib]: Failed to generate additional resources using 'eval_generate': SSL_connect returned=1 errno=0 state=unknown state: sslv3 alert certificate revoked
    Error: /File[/var/cache/puppet/lib]: Could not evaluate: Could not retrieve file metadata for puppet:///plugins: SSL_connect returned=1 errno=0 state=unknown state: sslv3 alert certificate revoked
    Error: Could not retrieve catalog from remote server: SSL_connect returned=1 errno=0 state=unknown state: sslv3 alert certificate revoked
    Warning: Not using cache on failed catalog
    Error: Could not retrieve catalog; skipping run
    Error: Could not send report: SSL_connect returned=1 errno=0 state=unknown state: sslv3 alert certificate revoked

Puppet Docs 2016b).


# Lähteet

Alex Nederlof blog 2013. Running and Testing Puppet Master Locally. 
Luettavissa: http://alex.nederlof.com/blog/2013/12/25/running-and-testing-puppet-master-locally/. Luettu 2.5.2017.

John Foderaro blog 2016. How to Set Up a Local Linux Environment with Vagrant.
Luettavissa: https://medium.com/@JohnFoderaro/how-to-set-up-a-local-linux-environment-with-vagrant-163f0ba4da77. Luettu 2.5.2017.

The Linux Juggernaut 2014. PUPPET: AUTO SIGN CERTIFICATIONS FROM NODES.
Luettavissa: http://www.linuxnix.com/puppet-auto-sign-certifications-from-nodes/. Luettu: 9.5.2017.

The JML Continuum 2013. Puppet: Exiting; no certificate found and waitforcert is disabled. 
Luettavissa: http://thejmlcontinuum.blogspot.fi/2013/08/puppet-exiting-no-certificate-found-and.html. Luettu 2.5.2017.

Puppet Docs 2016a. SSL: Regenerating all Certificates in a Puppet deployment.
Luettavissa: https://docs.puppet.com/puppet/4.7/ssl_regenerate_certificates.html. Luettu 2.5.2017.

Puppet Docs 2016b. Installing Puppet agent: Linux. 
Luettavissa: https://docs.puppet.com/puppet/4.10/install_linux.html. Luettu 2.5.2017.

Puppet Docs 2016c. Puppet Server: Installing From Package. 
Luettavissa: https://docs.puppet.com/puppetserver/2.7/install_from_packages.html. Luettu 2.5.2017.

Puppet Docs 2017. Hello world! Quick start guide. 
Luettavissa: https://docs.puppet.com/puppet/4.10/quick_start_helloworld.html. Luettu 2.5.2017.

Stack overflow 2011. Echo newline in Bash prints literal \n. 
Luettavissa: http://stackoverflow.com/questions/8467424/echo-newline-in-bash-prints-literal-n. Luettu 2.5.2017.

---
Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com

