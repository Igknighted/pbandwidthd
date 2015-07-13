A simple utility daemon for logging bandwidth usage by IP.  
  
__Setup__  
You can quickly deploy the files onto your server by running the following:  
```
curl -s https://raw.githubusercontent.com/Igknighted/pbandwidthd/master/bootstrap.sh | bash
```
  
This command will also update pbandwidthd's files.  
  
__Usage__  
If you're using a server that still uses the old system command, below are the commands you'll want to run.  
Start on boot: `chkconfig pbandwidthd on`  
Start the service: `system start pbandwidthd`  
Stop the service: `system start pbandwidthd`  
  
If you're running a newer system with systemd that uses the systemctl commands:  
Start on boot: `systemctl enable pbandwidthd`  
Start the service: `systemctl start pbandwidthd`  
Stop the service: `systemctl stop pbandwidthd`  
  
If you're on a server where neither of these options are available, you can just do the following:  
Start the service: `/usr/local/bin/pbandwidthd.pl`  
Stop the service:  `/usr/local/bin/pbandwidthd.pl stop`  
  
All of the data is stored in /var/log/pbandwidthd. The files in that directory contain data on bandwidth useage per IP address. I recommend using logrotate or another tool to rotate out the data.   
  
__Requirements__  
The requirements for pbandwidthd.pl to work are:  
```
perl
tcpdump
kill
```
  
  
Note: This has only been tested on RHEL 6 and RHEL 7. Mileage may vary.
