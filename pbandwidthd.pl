#!/usr/bin/perl

# pbandwidthd - perl bandwidth logger tool
#
# This tool will log bandwidth consumption to/from the server and provide
# useful information as to which IPs and ports are wasting precious network
# resources.
# 
# This does not support UDP at this time

my $logdir = "/var/log/pbandwidthd"; # directory we will store log info in
my $ticks_reset = 100; # this is how many ticks happen before the packet buffer resets
my $ticks = 0;           # initial tick is 0

my %compound_data; # this is the hash table that stores ip packet statistics
# %compound_data{ip_address} structure
# in		- This is the total amount of data sent to the server
# out		- This is the total amount of data the server set to the ip
# [0-9]+in	- This is the total amount of data send to the server over a specific port
# [0-9]+out	- This is the total amount of data send to the ip over a specific port

my $protocol = "NOTSET";

# Get our local IPs and turn them into a matchable regex
my $locals = `hostname -i`;
$locals =~ s/\n//g;
$locals =~ s/ /\|/g;
$locals =~ s/\./\\./g;


# create our log directory if it doesn't exist
if (! -d $logdir){
	mkdir($logdir);
}
if (! -d $logdir){
	print "$logdir does not exist.";
	exit 1;
}

# Start a TCP dump so we can parse through it to preserve bandwidth data.
# NOTE: to log only port 80
# open STDIN, '-|', 'tcpdump -vnni any port 80';
open STDIN, '-|', 'tcpdump -vnni any 2>/dev/null';
while ($line = <>) {

	# inside of this mechanism, we will take $compound_data and store the info in files.
	if($ticks >= $ticks_reset){
		for (keys %compound_data){
			my $ipaddr = $_;
			my $logfile = "$logdir/$ipaddr";

			# read in existing data and add it to current measurements
			open (MYFILE, "< $logfile");
			while (<MYFILE>) { chomp;
				# split the data line
				my @stored_info = split(": ", $_);
				# add the shit together
				$compound_data{$ipaddr}{$stored_info[0]} += $stored_info[1];
			}
			# fuck you file!
			close(MYFILE);


			# build our new formated file
			my $ipaddrdatafile = "";
			for(keys $compound_data{$ipaddr}){
				my $field = $_;
				$ipaddrdatafile =  "$ipaddrdatafile$field: $compound_data{$ipaddr}{$field}\n";
			}


			# write out the new log data
			open (MYFILE, "> $logfile");
			print MYFILE "$ipaddrdatafile";
			close(MYFILE);
		}


		# reset the compound_data table
		undef %compound_data;
		my %compound_data;

		# reset the ticks to zero!
		$ticks=0;
	}


	if($protocol eq "TCP"){
		# since we're processing TCP, the $line should look like this:
		#          23.253.224.117.22 > 72.3.128.84.23483: Flags [P.], cksum 0xc340 (incorrect -> 0x3cf5), seq 206785:207377, ack 240, win 316, options [nop,nop,TS val 6277983 ecr 2367950115], length 592

		# dirty split the TCP lines
		my @ips = split(':', $line, 2);
		my @ips = split(' ', $ips[0]);
		my @ipas = split('\.', $ips[0], 5);
		my @ipbs = split('\.', $ips[2], 5);
		my @ta = split(/length |\n/, $line);

		# set the first ip
		my $ipa = $ipas[0] . "." . $ipas[1] . "." . $ipas[2] . "." . $ipas[3];
		# set the first port
		my $porta = $ipas[4];
		# set the 2nd ip
		my $ipb = $ipbs[0] . "." . $ipbs[1] . "." . $ipbs[2] . "." . $ipbs[3];
		# set the 2nd port
		my $portb = $ipbs[4];

		# get the length of the content
		my $length = $ta[1];

		# figure out if it is inbound or outbound
		my $flow = "undef";
		if($ipa =~ /$locals/){
			$flow = "out";
		}else{
			$flow = "in";
		}


		# at this point we only have 6 variables we will use.
		# $flow - this lets us know if the traffic is inbound or outbound.
		#         if flow is "out" this server is sending data to $ipa
		#         if flow is "in" this server is receiving data from $ipa
		#         the fallback condition is "undef" which means we just don't know
		#
		# $ipa - If the $flow is "out" this is the remote source
		#        If the $flow is "in" this is the server we are on
		#
		# $porta - Service port in use for $ipa, only relevant when $flow is "in"
		#
		# $ipb - if the $flow is "out" this is the server we are on
		#        if the $flow is "in" this is the remote source
		#
		# $portb - Service port in use for $ipb, only relevant when $flow is "out"

		#print $flow, " ", $ipa, ":", $porta, " -> ", $ipb, ":", $portb, " ... ", $length, "\n";

		my $ip;
		my $port;

		# figure out which is the remote IP and port in use
		if($flow eq "in"){
			$ip = $ipa;
			$port = $portb;
		} elsif($flow eq "out"){
			$ip = $ipb;
			$port = $porta;
		}

		# ensure the IP is in the compound_data hash table
		if(! exists $compound_data{$ip}){
			$compound_data{$ip}{"total in"} = 0;
			$compound_data{$ip}{"total out"} = 0;
		}

		# ensure port is in hashtable
		if(! exists $compound_data{$ip}{"$port $flow"}){
			$compound_data{$ip}{"$port $flow"} = 0;
		}


		# lazy math
		$compound_data{$ip}{"total $flow"} += $length;
		$compound_data{$ip}{"$port $flow"} += $length;

	}

	# get the protocol if it is not set
	if($protocol eq "NOTSET"){
		# this is an example of what $line currently should be
		#        06:38:34.644690 IP (tos 0x10, ttl 64, id 38683, offset 0, flags [DF], proto TCP (6), length 644)

		# split some things
		my @ta = split("proto ", $line, 2);
		my @ta = split(" ", $ta[1], 2);

		# assign our final value
		$protocol = $ta[0];
	}else{
		# reset the protocol when we process the data it gave us.
		$protocol = "NOTSET";

		# increase the tick number. This is used to intermittently store bandwidth data.
		$ticks++;
	}

}
