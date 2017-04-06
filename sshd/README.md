# OpenSSH palvelun asennus ja määrittely

# Kesken - ei valmis

Käytin alustana Oracle VM VirtualBox v5.1.18 virtuaaliympäristössä toimivaa 
Xubuntu 16.10 32bit versiota.

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

# Moduulin teko

Perinteisesti loin ensin kansiot:

```sudo mkdir -p /etc/puppet/modules/sshd/{manifests,templates}```

Lähde: Ubuntu 16.04 LTS – How To Install and Configure SSH 2016. Luettavissa: http://linux-sys-adm.com/ubuntu-16.04-lts-how-to-install-and-configure-ssh/. Luettu: 6.4.2017

Lähde: Markdown Cheatsheet 2016. Luettavissa: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet. Luettu: 6.4.2017. 

Lähde: Puppet CookBook. Luettavissa: https://www.puppetcookbook.com/posts/exec-onlyif.html. Luettu 6.4.2017.

Lähde: Create a simple puppet class to maintain sshd 2011. Luettavissa: https://www.linuxsysadmintutorials.com/create-a-simple-puppet-class-to-maintain-sshd. Luettu: 6.4.2017.

---
Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
