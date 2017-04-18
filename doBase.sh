# !/bin/bash
# LiveUSB alkuasetuksien asennus scripti
# Versio 18042017.2

# Poistetaan nykyinen apt repository lista ja lisätään uudet lähteet
echo ""
echo "* Poistetaan nykyinen apt repository lista ja lisätään uudet lähteet *"
echo ""

sudo rm /etc/apt/sources.list && sudo touch /etc/apt/sources.list
OUT=$?
if [ $OUT = 0 ]; then
  echo '*** [ Poistetttu sources.list && luotu uusi ]***'
else
  echo '*** [ sources.list poisto epäonnistui ]***'
fi

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
OUT=$?
if [ $OUT = 0 ]; then
  echo '***[ GIT asetukset konfiguroitu ]***'
else
  echo '***[ GIT asetuksien konfigurointi epäonnistui ]***'
fi


# Kloonataan keskitettyHallinta repository
echo ""
echo "* Kloonataan keskitettyHallinta repository *"
echo ""
cd ~
git clone https://github.com/TommiKurjensalo/keskitettyHallinta.git
cd keskitettyHallinta/

# Kopioidaan tarvittavat tiedostot & luodaan puppet/modules linkki
echo ""
echo "* Kopioidaan:							*"
echo "*  - globaali gitconfig => /etc/gitconfig 			*"
echo "*  - bash_aliases 						*"
echo "* Tehdään linkki ~/keskitettyHallinta => /etc/puppet/modules 	*"
echo ""


sudo cp ~/keskitettyHallinta/conf/puppet.conf /etc/puppet/puppet.conf
OUT=$?
if [ $OUT = 0 ]; then
  echo '**[ Kopioitu puppet.conf onnistuneesti ]***'
else
  echo '**[ puppet.conf kopioiminen epäonnistui ]***'
fi


sudo cp ~/keskitettyHallinta/modules/git/templates/gitconfig.erb /etc/gitconfig
OUT=$?
if [ $OUT = 0 ]; then
  echo '***[ Kopioitu /etc/gitconfig onnistuneesti ]***'
else
  echo '***[ /etc/gitconfig kopioiminen epäonnistui ]***'
fi

cp ~/keskitettyHallinta/conf/bash_aliases ~/.bash_aliases
OUT=$?
if [ $OUT = 0 ]; then
  echo '***[ Kopioitu ~./bash_aliases onnistuneesti ]***'
else
  echo '***[ ~/.bash_aliases kopioiminen epäonnistui ]***'
fi


# Tarkistetaan onko kohdehakemistoa olemassa, jos ei niin luodaan linkki
if [ ! -d "/etc/puppet/modules" ]; then
 sudo ln -s ~/keskitettyHallinta/modules/ /etc/puppet/
 echo '***[ /etc/puppet/modules kansio luotu & tehty linkki  ]***'
else
 sudo mv -f /etc/puppet/modules/ /etc/puppet/oldModules/
 sudo ln -s ~/keskitettyHallinta/modules/ /etc/puppet/
 echo '***[ /etc/puppet/modules kansio nimetty uudelleen & linkki luotu  ]***'
fi


# Refreshataan ~/.bash_aliases
echo ""
echo "* Ladataan ~/.bash_aliases uudelleen *"
echo ""
source ~/.bash_aliases

echo ""
echo "*  .:[ VALMIS ]:.  *"
echo ""

