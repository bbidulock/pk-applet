#!/usr/bin/perl

use Net::DBus;
use Net::DBus::Dumper;

my ($bus,$srv,$obj);

$bus = Net::DBus->system;

$srv = $bus->get_service("org.freedesktop.DBus");
$obj = $srv->get_object("/org/freedesktop/DBus");
foreach (@{$obj->ListNames}) {
	print "$_\n";
}

#print dbus_dump($bus);
$srv = $bus->get_service("name.marples.roy.dhcpcd");
#print dbus_dump($srv);
$obj = $srv->get_object("/name/marples/roy/dhcpcd");
print dbus_dump($obj);
print "-----------------------\n";
print "-----------------------\n";
my @ifaces = (@{$obj->ListInterfaces});
foreach my $iface (@ifaces) {
	print "$iface:\n";
	my $result = $obj->ListNetworks($iface);
	print "result=$result\n";
	foreach my $net (@{$result}) {
		print "net=$net\n";
		foreach my $fld (@{$net}) {
			print "$fld\n";
		}
	}
}

print "Status: ", $obj->GetStatus, "\n";

foreach my $name (@{$obj->GetConfigBlocks("eth0")}) {
	print "$name\n";
}
my $int = $obj->GetInterfaces;
foreach my $k (keys %{$int}) {
	my $v = $int->{$k};
	print "$k: $v\n";
	foreach my $k2 (keys %{$v}) {
		my $v2 = $v->{$k2};
		print " $k2: ";
		if (ref $v2 eq 'ARRAY') {
			print join(',',@$v2),"\n";
		} elsif (ref $v2 eq 'HASH') {
			print join(';',map{"$_:$v2->{$_}"} keys %{$v2}), "\n";
		} else {
			print "$v2\n";
		}
	}
}

