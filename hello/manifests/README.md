# Harjoitustehtävä 'Hello World!'

Tehtiin yksinkertainen ohjelma, jolla voidaan todentaa moduulien toimintaa puppetissa.

Harjoitus tehtiin Haaga-Helia Pasilan luokassa 5004. Käyttöjärjestelmänä toimi Xubuntu 14.10, joka pyöri usb-tikulta live-tilassa.

**Puppet 4.9 reference manual 2017. Resource Type Reference (Single-Page). File resource. Lähde: https://docs.puppet.com/puppet/latest/type.html#file**

Koodi: /etc/puppet/modules/hello/manifests/init.pp

```
class hello {

	# Luodaan /tmp/helloModule tiedosto, jonka sisällä on teksti 'Hello World!'
	# Varmistetaan, että checksum tyyppi on md5. 
	# Määritetään myös tiedoston oikeudet 0744 = u+rwx g+rwx o+r
	file { '/tmp/helloModule':
		content => "Hello World!\n",
		checksum => "md5",
		mode => "0774"
	}
}
```

Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
