#!/usr/bin/perl

my $interface_cmds;

if (eval { require IO::Interface::Simple; }) {
	eval { import IO::Interface::Simple; };
	$interface_cmds='IO::Interface::Simple';
}

if (eval { require Net::Interface; }) {
	eval { import Net::Interface; };
	$interface_cmds='Net::Interface';
}

if ($interface_cmds eq 'IO::Interface::Simple') {

	my @interfaces = IO::Interface::Simple->interfaces;

	foreach my $if (@interfaces) {
		print "interface = $if\n";
		print "addr=       ",$if->address,"\n",
		      "broadcast = ",$if->broadcast,"\n",
		      "netmask =   ",$if->netmask,"\n",
		      "dstaddr =   ",$if->dstaddr,"\n",
		      "hwaddr =    ",$if->hwaddr,"\n",
		      "mtu =       ",$if->mtu,"\n",
		      "metric =    ",$if->metric,"\n",
		      "index =     ",$if->index,"\n";
	}

} else {

	my @interfaces = Net::Interface->interfaces;

	foreach my $if (@interfaces) {
		print "interface = $if\n";
		print "addr=       ",join(',',map {Net::Interface::inet_ntoa($_)} $if->address),"\n",
		      "broadcast = ",join(',',map {Net::Interface::inet_ntoa($_)} $if->broadcast),"\n",
		      "netmask =   ",join(',',map {Net::Interface::inet_ntoa($_)} $if->netmask),"\n",
		      "destination=",join(',',map {Net::Interface::inet_ntoa($_)} $if->destination),"\n",
		      "hwaddr =    ",$if->mac_bin2hex,"\n",
		      "mtu =       ",$if->mtu,"\n",
		      "metric =    ",$if->metric,"\n",
		      "index =     ",$if->index,"\n";
	}
}

