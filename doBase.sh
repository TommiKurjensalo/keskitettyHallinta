# !/bin/bash
# LiveUSB alkuasetuksien asennus scripti
# Versio 07042017.1

# Poistetaan nykyinen apt repository lista ja lisätään uudet lähteet
echo ""
echo "* Poistetaan nykyinen apt repository lista ja lisätään uudet lähteet *"
echo ""
sudo apt-add-repository "deb http://se.archive.ubuntu.com/ubuntu/ yakkety main restricted universe multiverse"
sudo apt-add-repository "deb http://se.archive.ubuntu.com/ubuntu/ yakkety-updates main restricted universe multiverse"
sudo apt-add-repository "deb http://se.archive.ubuntu.com/ubuntu/ yakkety-security main restricted universe multiverse"

# Asennetaan git & puppet
echo ""
echo "* Asennetaan git & puppet *"
echo ""
sudo apt-get update
sudo apt-get install -y git puppet

# Konfiguroidaan git global asetukset
echo ""
echo "* Konfiguroidaan käyttäjäkohtaiset git asetukset *"
echo ""
git config --global user.email "tommi.kurjensalo@myy.haaga-helia.fi"
git config --global user.name "Tommi Kurjensalo"

# Kloonataan keskitettyHallinta repository
echo ""
echo "* Kloonataan keskitettyHallinta repository *"
echo ""
cd ~
git clone https://github.com/TommiKurjensalo/keskitettyHallinta.git
cd keskitettyHallinta/

# Kopioidaan puppet moduulit ja config tiedosto
echo ""
echo "* Kopioidaan puppet moduulit ja config tiedosto *"
echo "* Kopioidaan globaali gitconfig => /etc/gitconfig *"
echo ""
sudo cp -R ~/keskitettyHallinta/modules/ /etc/puppet/modules
sudo cp ~/keskitettyHallinta/conf/puppet.conf /etc/puppet/puppet.conf
sudo cp ~/keskitettyHallinta/modules/git/templates/gitconfig.erb /etc/gitconfig
