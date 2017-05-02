# Puppet Master-slave luominen ja testaaminen

Käytin alustana [Oracle VM VirtualBox](https://www.virtualbox.org/) v5.1.18 virtuaaliympäristössä toimivaa [Xubuntu 16.10 32bit](http://se.archive.ubuntu.com/mirror/cdimage.ubuntu.com/xubuntu/releases/16.10/release/) versiota.

Aloittelin testailun noin 13 aikoihin.

Puppet versio=4.5.2 ja ruby_version=2.3.1.

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

 $ sudo service puppet-master stop
 $ sudoedit /etc/puppet/puppet.conf

# Määrittelyä

Puppet.conf sisältö muutoksien jälkeen. Lisäsin dns_alt_names perään koneen nimeni ja 
[agent] lohkon server tietoineen.

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

Herjojakin tuli

 -- puppet agent ei vain löydä konekohtaisia määrityksiä
 Warning: Unable to fetch my node definition, but the agent run will continue:
 Warning: Server hostname 'lag-vm.local' did not match server certificate; expected one of lag-vm, 
 DNS:lag-vm, DNS:puppet
 
 -- iso liuta valituksia certifikaatin epäyhteensopivuudesta, 
 koska sitä ei ole vielä edes hyväksytty palvelimen puolelta.
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
 Info: Certificate Request fingerprint (SHA256): BB:91:CB:E6:0D:E6:EA:35:C9:45:DD:27:3A:BC:91:14:7C:7E:0E:EC:FF:C9:80:46:9F:2F:70:32:9F:44:0B:20
 Notice: lag-vm has a waiting certificate request
 Notice: Signed certificate request for lag-vm
 Notice: Removing file Puppet::SSL::CertificateRequest lag-vm at '/var/lib/puppet/ssl/ca/requests/lag-vm.pem'
 Notice: Removing file Puppet::SSL::CertificateRequest lag-vm at '/var/lib/puppet/ssl/certificate_requests/lag-vm.pem'
 Warning: The WEBrick Puppet master server is deprecated and will be removed in a future release. Please use Puppet Server instead. See http://links.puppetlabs.com/deprecate-rack-webrick-servers for more information.
    (at /usr/lib/ruby/vendor_ruby/puppet/application/master.rb:210:in `main')
 Notice: Starting Puppet master version 4.5.2

  -- tämä tehdään vasta kun agentin sertit on poistettu.
Käynnistetään puppet masteri

 $ sudo puppet resource service puppet-master ensure=running

## Luodaan sertifikaatit agentille uudelleen

Sammutetaan puppet agent

 $ sudo puppet resource service puppet-agent ensure=stopped

Poistetaan sertifikaatit

 $ sudo rm -rf /var/lib/puppet/ssl 

Käynnistetään palvelu uudelleen

 $ sudo puppet resource service puppet-agent ensure=running

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

