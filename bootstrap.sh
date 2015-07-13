#!/bin/bash
rm -rf /usr/local/bin/pbandwidthd.pl /etc/init.d/pbandwidthd /etc/systemd/system/pbandwidthd.service 2>&1 > /dev/null

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


if ! which tcpdump > /dev/null 2>&1; then
  echo
  echo
  echo
  echo
  echo -e "Make sure you install \e[31m tcpdump \e[0m or pbandwidthd will not work.\n"
fi
