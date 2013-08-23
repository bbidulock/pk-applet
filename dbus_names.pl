#!/usr/bin/perl

use Net::DBus;
use Net::DBus::Dumper;

my ($bus,$srv,$obj);
$bus = Net::DBus->system(nomainloop=>1);
$srv = $bus->get_service("org.freedesktop.DBus");
$obj = $srv->get_object("/org/freedesktop/DBus");
foreach (@{$obj->ListNames}) {
	print "$_\n";
}
$bus = Net::DBus->session(nomainloop=>1);
$srv = $bus->get_service("org.freedesktop.DBus");
$obj = $srv->get_object("/org/freedesktop/DBus");
foreach (@{$obj->ListNames}) {
	print "$_\n";
}
