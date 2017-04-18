# Perusasetuksien määrittely yhdellä komennolla

Ideana on saada LiveUSB ympäristö haluttuun toimintakuntoon yhdellä tiedoston ajolla.

Tämä on testattu 5.4.2017 Haaga-Helian labrassa 5004 PC numerolla 15 käyttäen LiveUSB tikkua.
Käyttöjärjestelmänä oli Xubuntu 16.10 32bit.

doBase.sh tekee seuraavat toimenpiteet:
- Poistetaan nykyinen apt repository lista ja lisätään uudet lähteet
- Asennetaan git & puppet
- Konfiguroidaan git global asetukset
- Kloonataan keskitettyHallinta repository
- Kopioidaan: 
 - globaali gitconfig => /etc/gitconfig bash_aliases 
- Luodaan /etc/puppet/modules kansio, JOS sitä ei ole olemassa
- Tehdään linkki ~/keskitettyHallinta => /etc/puppet/modules
- Refreshataan ~/.bash_aliases 

Lataa tiedosto githubista komennolla:

  $ wget https://raw.githubusercontent.com/TommiKurjensalo/keskitettyHallinta/master/doBase.sh

Lopuksi suoritetaan komento:

  $ bash doBase.sh

---
Tätä dokumenttia saa kopioida ja muokata GNU General Public License (versio 2 tai uudempi) mukaisesti. http://www.gnu.org/licenses/gpl.html

Pohjana Tero Karvinen 2017: Palvelinten hallinta, http://terokarvinen.com
