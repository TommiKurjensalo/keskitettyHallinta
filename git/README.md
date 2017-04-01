# Lisätehtävä 1 - Asenna ja määrittele jokin hyödyllinen ohjelma

Käytin alustana Oracle VM VirtualBox https://www.virtualbox.org/ v5.1.18 virtuaaliympäristössä toimivaa Xubuntu 16.10 32bit http://se.archive.ubuntu.com/mirror/cdimage.ubuntu.com/xubuntu/releases/16.10/release/ versiota.

Päätin asentaa git:in, koska sitä tulen aina tarvitsemaan koulussa tunneilla, kun käytän Xubuntua live-tilassa.

Etsiskelin ja testailin useamman tunnin kuinka määrittelytiedosto voidaan näppärästi kopioida kotihakemistoon. Törmäsin testeissäni seuraaviin ongelmiin.

- Kuinka saada selville haluttu käyttäjä, jonka kotihakemistoon asetus määritellään?
- Kuinka saada edes kopioitua haluama asetustiedosto paikallisesti eri kansioon hyödyntäen puppettia?

## Käyttäjänimen selvitys

Mielessäni kävi mm. hyödyntää for-looppia, jolla listataan /home kansio ja tästä saadaan muuttujalle käyttäjälista arvo käyttäjä käyttäjältä, mutta sitten mietin, että enhän välttämättä halua kaikille käyttäjille kopioida kyseistä tiedostoa.

Sitten mietin, että pitäisikö vain itse määritellä halutut käyttäjät muuttujaan ja loopata se läpi?

Lopuksi päädyin ratkaisuun, jossa vain yksinkertaisesti muutan halutun käyttäjänimen `$username` muuttujalle.

## Paketin asennus ja määrittelytiedoston kopiointi

Kun paketin asennus oli jo opittu edellisissä harjoitustehtävissä, niin hyödynsin osaamistani tähän.

Mutta itse konfiguraation tiedoston kopiointi olikin haastavampi homma. En tahtonut oikein millään käsittää source syntaxin toimivuutta, koska siitä oli yllättävän vähän hyviä esimerkkejä, tai minä en ainakaan niitä löytänyt.

Halusin saavuttaa tilanteen, jossa tiedosto kopioidaan pakotetusti kotihakemistoon ja sille annetaan myös oikeat oikeudet.

```
class git {

	package { git:
		ensure => "installed",
	}

	file { "/home/insp/.gitconfig":
		ensure => "file",
		replace => "true",
		purge => "true",
		mode => "0644",
		owner => "insp",
		group => "insp",
		source => "file:///etc/puppet/modules/git/files/git_config",
	}

}
```

Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
