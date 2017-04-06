# Perusasetuksien määrittely yhdellä komennolla

Ideana on saada LiveUSB ympäristö haluttuun toimintakuntoon yhdellä tiedoston ajolla.

doBase.sh tekee seuraavat toimenpiteet:
- Poistetaan nykyinen apt repository lista ja lisätään uudet lähteet
- Asennetaan git & puppet
- Konfiguroidaan git global asetukset
- Kloonataan keskitettyHallinta repository
- Kopioidaan puppet moduulit ja config tiedosto

Lataa tiedosto githubista komennolla:
`wget https://raw.githubusercontent.com/TommiKurjensalo/keskitettyHallinta/master/doBase.sh`

Lisää tiedostoon ajo-oikeudet `chmod u+x doBase.sh` tai `chmod 0744 doBase.sh`
