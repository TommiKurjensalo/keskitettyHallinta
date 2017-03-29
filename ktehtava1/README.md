# Kotitehtävä 1

Katsoin esimerkin kuinka voidaan käyttää muita resursseja kuin file käyttäen hyödykseni puppetcookbook sivustoa.

Jouduin lisäämään package resurssiin allowcdrom => "true" attribuutin, koska liveUSB:n käyttö vaatii sitä.

Lähde: https://www.puppetcookbook.com/posts/install-package.html


Halusin luoda file resurssiin jotain muuta kuin content attribuutin, jotenka etsin sopivia vaihtoehtoja
ja esimerkkejä docs.puppet.com sivulta.

Lähde: https://docs.puppet.com/puppet/latest/type.html#file

Koodi:

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
        # Jos tiedosto on jo olemassa, tehdään siitä backup muotoon ktehtava.puppet-bak
        file { '/tmp/ktehtava1':
                ensure => "present",
                content => "Timestamp: ${timestamp}",
                backup => "true"
        }
}
```

    Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

    Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
