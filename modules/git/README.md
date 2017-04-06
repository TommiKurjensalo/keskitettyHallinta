# Lisätehtävä 1 - Asenna ja määrittele jokin hyödyllinen ohjelma

Käytin alustana [Oracle VM VirtualBox](https://www.virtualbox.org/) v5.1.18 virtuaaliympäristössä toimivaa [Xubuntu 16.10 32bit](http://se.archive.ubuntu.com/mirror/cdimage.ubuntu.com/xubuntu/releases/16.10/release/) versiota.

Päätin asentaa git:in, koska sitä tulen aina tarvitsemaan koulussa tunneilla, kun käytän Xubuntua live-tilassa.

Aloittelin noin 19 aikoihin ja 23 jälkeen lopettelin. Osa ajasta kului siihen, kun ensin loin virtuaaliympäristön. Siihen ei tosin kulunnut pahemmin aikaa, mitä nyt kestää kun ladataan .iso image, virtualbox ja asennetaan Xubuntu.

Tätäkin kirjoitusta kun tein myös jälkikäteen, niin kaikessa muokkaamisessa ja testaamisessa meni yhteensä noin 2 tuntia.

Etsiskelin ja testailin useamman tunnin kuinka määrittelytiedosto voidaan näppärästi kopioida kotihakemistoon. Törmäsin testeissäni seuraaviin ongelmiin.

- Kuinka saada selville haluttu käyttäjä, jonka kotihakemistoon asetus määritellään?
- Kuinka saada edes kopioitua haluama asetustiedosto paikallisesti eri kansioon hyödyntäen puppettia?

## Käyttäjänimen selvitys

Mielessäni kävi mm. hyödyntää for-looppia, jolla listataan /home kansio ja tästä saadaan muuttujalle käyttäjälista arvo käyttäjä käyttäjältä, mutta sitten mietin, että enhän välttämättä halua kaikille käyttäjille kopioida kyseistä tiedostoa.

Sitten mietin, että pitäisikö vain itse määritellä halutut käyttäjät muuttujaan ja loopata se läpi?

Lopuksi päädyin ratkaisuun, jossa vain yksinkertaisesti muutan halutun käyttäjänimen `$username` muuttujalle.

## Paketin asennus ja määrittelytiedoston kopiointi

Kun paketin asennus oli jo opittu edellisissä harjoitustehtävissä, niin hyödynsin osaamistani tähän.

### Edit: 5.4.2017

Muutettu logiikka niin, että käytetään template tiedostoa, joka sisältää globaalit käyttäjäasetuset. Nämä kopioidaan /etc kansion alle. Käyttäjäkohtaiset asetukset voidaan joko määritellä suoraan moduuliin, [toiseen scriptiin](esim. (...../doBase.sh)

~~Mutta itse konfiguraation tiedoston kopiointi olikin haastavampi homma. En tahtonut oikein millään käsittää source syntaxin toimivuutta, koska siitä oli yllättävän vähän hyviä esimerkkejä, tai minä en ainakaan niitä löytänyt. Lopuksi onneksi löysin sivuston, jonka avulla aikani testattuani löysin oikean kombinaation.~~

~~Ongelmana oli se, että en tajunnut laittaa file:/// <-- 3x / merkkiä ja en tajunnut laittaa koko polkua vaan oletin, että pelkkä /modules/git/files olisi riittänyt, kuten puppet docs (https://docs.puppet.com/puppet/latest/type.html#package) lähteen esimerkissä käytetään.~~

~~**Stackoverflow 2012. Sourcing Puppet files from outside of modules. Lähde: http://stackoverflow.com/questions/9518905/sourcing-puppet-files-from-outside-of-modules**~~

~~Halusin saavuttaa tilanteen, jossa tiedosto kopioidaan pakotetusti kotihakemistoon ja sille annetaan myös oikeat oikeudet.~~

```
class git {

	# Haetaan paketti git ja asennetaan se.
	package { git:
		ensure => "installed",
	}

# Kopioidaan globaalit git asetukset /etc/gitconfig tiedostoon
	file { "/etc/gitconfig":
		ensure => "file",
		content => template('git/gitconfig.erb'),
}

}
```

# Aliakset

Ps. Jos et jaksa aina kirjoittaa samoja käskyjä uudelleen, esimerkiksi `sudo puppet apply -e 'class {"moduuli":}'` niin voit luoda näppäriä aliaksia.

Ainakin omassa koneessani on automaationa rivi ~/.bashrc tiedostossa, joka etsii ~/.bash_aliases tiedostoa ja lataa sen jos se löytyy. Loin siis tiedoston käskyllä `nano ~/.bash_aliases` ja lisäsin sinne muutaman rivin.

**DigitalOcean 2014. An Introduction to Useful Bash Aliases and Functions. Lähde: https://www.digitalocean.com/community/tutorials/an-introduction-to-useful-bash-aliases-and-functions**

```
# File: $HOME/.bash_aliases
# Omat aliakset

alias gclone='git clone https://github.com/TommiKurjensalo/keskitettyHallinta.git'
alias gpush='git add . && git commit; git pull && git push'
function apuppet () {
	sudo puppet apply -e 'class {"'$1'":}' 
}
```

Nyt pystyn käskyllä `gclone` kloonaamaan helposti github tiedostot, käsky `gpush` taas lisää nykyisen kansion git päivityslistaan, ajaa commitin, noutaa nykyiset tiedostot githubista ja lähettää omat tietoni githubiin.

Loin vielä funktion nimeltä `apuppet`, jolla säästyy tuo puppet apply.. käskyn koko litanian kirjoitus. Nyt minun pitää vain kirjoittaa `apuppet <moduulinimi>` ja homma toimii.

Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
