# !/bin/bash
# LiveUSB alkuasetuksien asennus scripti

# Poistetaan nykyinen apt repository lista ja lisätään uudet lähteet
echo "Poistetaan nykyinen apt repository lista ja lisätään uudet lähteet"
sudo apt-add-repository "deb http://se.archive.ubuntu.com/ubuntu/ yakkety main restricted universe multiverse"
sudo apt-add-repository "deb http://se.archive.ubuntu.com/ubuntu/ yakkety-updates main restricted universe multiverse"
sudo apt-add-repository "deb http://se.archive.ubuntu.com/ubuntu/ yakkety-security main restricted universe multiverse"

# Asennetaan git & puppet
echo "Asennetaan git & puppet"
sudo apt-get update
sudo apt-get install -y git puppet

# Konfiguroidaan git global asetukset
echo "Konfiguroidaan git global asetukset"
git config --global user.email "tommi.kurjensalo@myy.haaga-helia.fi"
git config --global user.name "Tommi Kurjensalo"
git config --global credential.helper "cache --timeout=3600"

# Luodaan keskitettyHallinta kansio
echo "Luodaan keskitettyHallinta kansio"
mkdir ~/keskitettyHallinta

# Kloonataan keskitettyHallinta repository
echo "Kloonataan keskitettyHallinta repository"
git clone https://github.com/TommiKurjensalo/keskitettyHallinta.git
cd keskitettyHallinta/

# Kopioidaan puppet moduulit ja config tiedosto
echo "Kopioidaan puppet moduulit ja config tiedosto"
sudo cp -R modules/ /etc/puppet/modules
sudo cp -y puppet.conf /etc/puppet/puppet.conf
