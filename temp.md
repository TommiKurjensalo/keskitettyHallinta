#!/bin/sh

CODENAME=$(grep "VERSION_CODENAME=" /etc/os-release |awk -F= {' print $2'}|sed s/\"//g)

echo 'sudo apt-add-repository "deb http://se.archive.ubuntu.com/ubuntu/' "${CODENAME}" 'main restricted universe multiver$

