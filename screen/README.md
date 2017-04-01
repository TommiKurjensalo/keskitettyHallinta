# Harjoitustehtävä - Moduulin luonti

Testasin yksinkertaisen moduulin luontia, joka tekee jotain muuta kuin käyttää hyödykseen file toimintoa.

Harjoitus tehtiin Haaga-Helia Pasilan luokassa 5004. Käyttöjärjestelmänä toimi Xubuntu 14.10, joka pyöri usb-tikulta live-tilassa.

**Puppet 4.9 reference manual 2017. Resource Type Reference (Single-Page). Package resource. Lähde: https://docs.puppet.com/puppet/latest/type.html#package**

Koodi: /etc/puppet/modules/screen/manifests/init.pp

```
class screen {

  # Asennetaan paketti screen, ja varmistetaan, että se on asennettu
  package { 'screen':
    ensure => 'installed',
  }
}
```

Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
