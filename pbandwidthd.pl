#!/usr/bin/perl

# pbandwidthd - perl bandwidth processor daemon/tool
#
# This tool will process bandwidth consumption to/from the server and provide
# useful information as to which IPs and ports are wasting precious network
# resources.
#
# Currently this is only wrapping around tcpdump and sorting some data for use. This doesn't really do anything yet.
# Will add UDP support soon.



my $protocol = "NOTSET";

# Get our local IPs and turn them into a matchable regex
my $locals = `hostname -i`;
$locals = $locals . " ::1 127.0.0.1";
$locals =~ s/\n//g;
$locals =~ s/ /\|/g;
$locals =~ s/\./\\./g;

# Start a TCP dump so we can parse through it to preserve bandwidth data.
open STDIN, '-|', 'tcpdump -vnni any port 80';
while ($line = <>) {
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

		print $flow, " ", $ipa, ":", $porta, " -> ", $ipb, ":", $portb, " ... ", $length, "\n";

		# TODO:
		#   We will log the following data...
		#   - Bandwidth consumption per port over IP
		#   - Bandwidth consuption per IP address
		#   - Bandwidth consumption per IP address over port and IP
		#
		#   This data should be rotatated daily around midnight or reset.
		#   Need to make tools to parse the data in a friendly manner (they will be CLI and apache GUI facing).

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
	}

}
