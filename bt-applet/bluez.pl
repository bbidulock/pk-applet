#!/usr/bin/perl

use Net::DBus;
use Net::DBus::Dumper;
use Net::DBus::Reactor;
use Data::Dumper;

my $reactor = Net::DBus::Reactor->main();

my ($bus,$srv,$obj);

$bus = Net::DBus->system;
$srv = $bus->get_service("org.bluez");
print dbus_dump($srv);
#print Dumper($srv);
my @objs = (sort keys %{$srv->{objects}});
foreach my $key (@objs) {
	print "Have object named: $key\n";
}
$obj = $srv->get_object("/");
print dbus_dump($obj);
my @adaptors = (@{$obj->ListAdapters});
foreach my $a (@adaptors) {
	print "Adaptor: $a\n";
}
if (my $a = $obj->DefaultAdapter) {
	print "Default Adaptor: $a\n";
}
$obj = $srv->get_object("/org/bluez");
#print dbus_dump($obj);
$obj = $srv->get_object("/org/bluez/test");
#print dbus_dump($obj);
#$obj = $srv->get_object("/org/bluez/24709/any");
#print dbus_dump($obj);

foreach my $a (@adaptors) {
	$obj = $srv->get_object($a);
	print dbus_dump($obj);
	my @devices = (@{$obj->ListDevices});
	print "Devices: \n";
	foreach my $d (@devices) {
		print "  Device: $d\n";
	}
	my @proxies = (@{$obj->ListProxies});
	print "Proxies: \n";
	foreach my $p (@proxies) {
		print "  Proxy: $p\n";
	}
}

my ($hash,$ctl,$dev,$ser,$inp);
$obj = $srv->get_object("/org/bluez/24709/hci0/dev_00_22_48_88_34_2B");
print dbus_dump($obj);
$dev = $srv->get_object("/org/bluez/24709/hci0/dev_00_22_48_88_34_2B", "org.bluez.Device");
$hash = $dev->GetProperties;
print "Device Properties:\n";
while (my ($key,$val) = each %$hash) {
	if (ref $val eq 'ARRAY') {
		print "  $key: ", join(',',@$val), "\n";
	} else {
		print "  $key: $val\n";
	}
}
$inp = $srv->get_object("/org/bluez/24709/hci0/dev_00_22_48_88_34_2B", "org.bluez.Input");
$hash = $inp->GetProperties;
print "Input Properties:\n";
while (my ($key,$val) = each %$hash) {
	if (ref $val eq 'ARRAY') {
		print "  $key: ", join(',',@$val), "\n";
	} else {
		print "  $key: $val\n";
	}
}
$obj = $srv->get_object("/org/bluez/24709/hci0/dev_90_21_55_F2_43_DC");
print dbus_dump($obj);
$ctl = $srv->get_object("/org/bluez/24709/hci0/dev_90_21_55_F2_43_DC", "org.bluez.Control");
$hash = $ctl->GetProperties;
print "Control Properties:\n";
while (my ($key,$val) = each %$hash) {
	if (ref $val eq 'ARRAY') {
		print "  $key: ", join(', ',@$val), "\n";
	} else {
		print "  $key: $val\n";
	}
}
$dev = $srv->get_object("/org/bluez/24709/hci0/dev_90_21_55_F2_43_DC", "org.bluez.Device");
$hash = $dev->GetProperties;
print "Device Properties:\n";
while (my ($key,$val) = each %$hash) {
	if (ref $val eq 'ARRAY') {
		print "  $key: ", join(',',@$val), "\n";
	} else {
		print "  $key: $val\n";
	}
}
$ser = $srv->get_object("/org/bluez/24709/hci0/dev_90_21_55_F2_43_DC", "org.bluez.Serial");

