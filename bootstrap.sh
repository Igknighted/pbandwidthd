#!/bin/bash
cd /usr/local/bin
wget https://raw.githubusercontent.com/Igknighted/pbandwidthd/master/pbandwidthd.pl
cd /etc/init.d
wget https://raw.githubusercontent.com/Igknighted/pbandwidthd/master/init.d/pbandwidthd
if [ -d /etc/systemd/system ]; then
  cd /etc/systemd/system
  wget https://raw.githubusercontent.com/Igknighted/pbandwidthd/master/init.d/pbandwidthd.service
fi
