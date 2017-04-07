# OpenSSH palvelun asennus ja määrittely

Käytin alustana Oracle VM VirtualBox v5.1.18 virtuaaliympäristössä toimivaa 
Xubuntu 16.10 32bit versiota.

Tein tehtävää 6.4.2017 noin 2 tuntia ja 7.4.2017 noin 2 tuntia.

Etsiskelin netistä tietoa, että kuinka kyseisen toiminnon voisi toteuttaa ja huomasin, 
että parametrejä ja vaihtoehtoja on runsaasti. Oikeastaan aivan liikaakin, mikäli haluaisi
järkevässä ajassa tehtyä sshd levitystä.

Yksi vaihtoehto voi olla, että käyttää suoraan jotain olemassaolevista paketeista ja testaa
kuinka ne toimii. Tai sitten etsiä kaikki 300 parametriä, testata, opetalla ja taistella
tie voittoon.

Itse lähdin helpomalle tavalla liikenteeseen, enkä tässä vaiheessa luonnut esimerkiksi avaimia
automaattisesti, enkä käyttänyt kaikkia puppet kikkoja mitä maanpäältään löytyy.

Tavoitteeni oli:

- Asentaa openssh-server
- Määritellä perusasetukset
- Testata toimivuus

Lähde: Markdown Cheatsheet 2016. Luettavissa: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet. Luettu: 6.4.2017. 

# Moduulin teko

Loin ensin kansiot:

	 $ sudo mkdir -p /etc/puppet/modules/sshd/manifests

Tämän jälkeen metsästin lähteiden avulla tietoa, että minkälaisen init.pp tiedoston sitä edes osaisi tehdä. Lopuksi löysin hyvän pohjan, josta lähdin eteenpäin. Siinä käytettiin hyödykseen `package`, `service` ja `augeas` resursseja.

Lähde: Ubuntu 16.04 LTS – How To Install and Configure SSH 2016. Luettavissa: http://linux-sys-adm.com/ubuntu-16.04-lts-how-to-install-and-configure-ssh/. Luettu: 6.4.2017

Lähde: Create a simple puppet class to maintain sshd 2011. Luettavissa: https://www.linuxsysadmintutorials.com/create-a-simple-puppet-class-to-maintain-sshd. Luettu: 6.4.2017.

Lähde: Puppet CookBook. Luettavissa: https://www.puppetcookbook.com/posts/exec-onlyif.html. Luettu 6.4.2017.


# Ongelmat ja niiden selättäminen

Testasin ajaa luotua moduuliani seuraavalla komennolla:

	  $ sudo puppet apply -v -e 'class {"sshd":}' --noop

Tietenkään hommat ei suoraan lähtenyt toimimaan, ja virheitä olivat:

	  Warning: Could not find resource 'Service["sshd"]' in parameter 'notify'
	  (at /etc/puppet/modules/sshd/manifests/init.pp:17)
	  Warning: Could not find resource 'Augeas[openssh-server]' in parameter 'require'
	  (at /etc/puppet/modules/sshd/manifests/init.pp:23)
	  Notice: Compiled catalog for lag-vm in environment production in 0.84 seconds
	  Error: Could not find dependent Service["sshd"] for Augeas[sshd_config] at /etc/puppet/modules/sshd/manifests		/init.pp:16

Hyödynsin "uutta" käskyä löytämään paremmin ongelmakohdat.

	  $ sed -n 16,24p init.pp
  
Näin sain rivit 16-24 näkyville.

Lähde: With the Linux “cat” command, how do I show only certain lines by number 2016. Luettavissa:http://unix.stackexchange.com/questions/288521/with-the-linux-cat-command-how-do-i-show-only-certain-lines-by-number. Luettu: 7.4.2017.

Ongelmana oli se, että ->

	augeas { "sshd_config":
		content => "/files/etc/ssh/sshd_config", <-- alunperin olin kirjoittanut `content`, 
		enkä `context` ja polussa pitää olla `/files` 
		changes => [ 	"set PasswordAuthentication yes",
				"set UsePam yes",
				"set PermitRootLogin no",
			         ],
		require => Package["openssh-server"],
		notify => 'Service["ssh"]', <-- Service käskyä ympäröi hipsut ' '
	}

Näiden ongelmien korjaamisen jälkeen moduuli asentui mukisematta.

	  $ sudo puppet apply -v -e 'class {"sshd":}'
	  Notice: Compiled catalog for lag-vm in environment production in 0.80 seconds
	  Info: Applying configuration version '1491584244'
	  Notice: /Stage[main]/Sshd/Package[openssh-server]/ensure: created
	  Notice: /Stage[main]/Sshd/Augeas[sshd_config]/returns: executed successfully
	  Info: /Stage[main]/Sshd/Augeas[sshd_config]: Scheduling refresh of Service[sshd]
	  Notice: /Stage[main]/Sshd/Service[sshd]/ensure: ensure changed 'stopped' to 'running'
	  Info: /Stage[main]/Sshd/Service[sshd]: Unscheduling refresh on Service[sshd]
	  Notice: Applied catalog in 9.35 seconds

# Testaus

Varmistetaan, että ssh service on päällä

	  $ service --status-all |grep ssh
	    [ + ]  ssh

Katsotaan sshd_config tiedoston sisältö

	  $ egrep -wi --color 'PasswordAuthentication|UsePam|PermitRootLogin' /etc/ssh/sshd_config 
	  PermitRootLogin no
	  #PasswordAuthentication yes
	  # PasswordAuthentication.  Depending on your PAM configuration,
	  # the setting of "PermitRootLogin without-password".
	  # PAM authentication, then enable this but set PasswordAuthentication
	  UsePAM yes
	  PasswordAuthentication yes
	  UsePam yes

Kaikki muut on ok, paitsi UsePam on kahteen kertaan, koska olen kirjoittanut scriptiini UsePam, enkä UsePAM ! Pitänee tehdä muutos. Nyt otin manuaalisesti tuon vikan rivin pois `/etc/ssh/sshd_config` tiedostosta.

Yhteystestausta

	  $ ssh insp@localhost
	  The authenticity of host 'localhost (127.0.0.1)' can't be established.
	  ECDSA key fingerprint is SHA256:gbeE1F8Cj1GeoMZcc5KNvL9pySfQtqFxOfC7RQUzAbo.
	  Are you sure you want to continue connecting (yes/no)? yes
	  Warning: Permanently added 'localhost' (ECDSA) to the list of known hosts.
	  insp@localhost's password: 
	  Welcome to Ubuntu 16.10 (GNU/Linux 4.8.0-46-generic i686)

	   * Documentation:  https://help.ubuntu.com
	   * Management:     https://landscape.canonical.com
	   * Support:        https://ubuntu.com/advantage

	  134 packages can be updated.
	  0 updates are security updates.

	  Last login: Fri Apr  7 19:58:51 2017 from 10.0.2.2
	  insp@lag-vm:~
	  $ 

DONE !

---
Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
