# Palvelinten hallinta
Linux Palvelinten hallinta

## Git

  $ git config --global user.email "tommi.kurjensalo@myy.haaga-helia.fi"
  $ git config --global user.name "Tommi Kurjensalo"
  $ git config --global credential.helper "cache --timeout=3600"
  $ git clone https://github.com/TommiKurjensalo/keskitettyHallinta.git
  $ cd keskitettyHallinta/
  $ git add . && git commit; git pull && git push

## puppet.conf

Lisää basemodulepath `[main]` lohkoon, jotta `--modulepath` syntaksia ei tarvitse käyttää.

`basemodulepath = $confdir/modules:/etc/puppet/modules`
