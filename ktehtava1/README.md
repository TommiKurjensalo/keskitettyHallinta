# Kotitehtävä 1 - Tee moduuli, joka käyttää ainakin kahta eri resurssia

Katsoin esimerkin kuinka voidaan käyttää muita resursseja kuin file käyttäen hyödykseni puppetcookbook sivustoa.

Päätin ottaa package resurssin, jolla pystyn asentemaan halutun paketin.
Jouduin lisäämään package resurssiin `allowcdrom => "true"` attribuutin, koska live tilassa ei voi muuten asentaa paketteja.

Puppet CookBook 2015. Install a package. Lähde: https://www.puppetcookbook.com/posts/install-package.html


Halusin luoda file resurssiin jotain muuta kuin content attribuutin, jotenka etsin sopivia vaihtoehtoja
ja esimerkkejä [Puppet Documentation] (https://docs.puppet.com) sivulta.

Puppet 4.9 reference manual 2017. Resource Type Reference (Single-Page). File resource. Lähde: https://docs.puppet.com/puppet/latest/type.html#file


init.pp:

```class ktehtava1 {

        # Asennetaan paketti screen ja varmistetään, että se tulee asennetuksi.
        # allowcdrom attribuutti vaaditaan liveUSB käytössä.
        package { 'screen':
                ensure => "installed",
                allowcdrom => "true"
        }

        # Luodaan timestamp muuttuja, jolle annetaan arvo date käskyä hyödyntäen.
        # Timestampin ulkoasu on muotoa yyyymmdd_hh:mm:ss
        $timestamp = generate('/bin/date', '+%Y%m%d_%H:%M:%S')

        # Luodaan tiedosto /tmp/ktehtava1, tarkistetaan onko tiedosto jo olemassa.                
        # Sisältöön lisätään Timestamp: yyyymmdd_hh:mm:ss
        # Jos tiedosto on jo olemassa, tehdään siitä backup muotoon ktehtava1.puppet-bak
        file { '/tmp/ktehtava1':
                ensure => "present",
                content => "Timestamp: ${timestamp}",
                backup => "true"
        }
}
```

Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. 

http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
