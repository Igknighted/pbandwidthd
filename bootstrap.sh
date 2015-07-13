#!/bin/bash

if [ -d /usr/local/bin ]; then
  mkdir -p /usr/local/bin
fi

cd /usr/local/bin
wget https://raw.githubusercontent.com/Igknighted/pbandwidthd/master/pbandwidthd.pl
chmod +x pbandwidthd.pl

if [ -d /etc/init.d ]; then
  cd /etc/init.d
  wget https://raw.githubusercontent.com/Igknighted/pbandwidthd/master/extra/pbandwidthd
fi

if [ -d /etc/systemd/system ]; then
  cd /etc/systemd/system
  wget https://raw.githubusercontent.com/Igknighted/pbandwidthd/master/extra/pbandwidthd.service
fi
