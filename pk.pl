#!/usr/bin/perl

use Net::DBus;
use Net::DBus::Dumper;
use Net::DBus::Reactor;

my $reactor = Net::DBus::Reactor->main();

my ($ebus,$esrv,$eobj);
my ($ybus,$ysrv,$yobj);

$ebus = Net::DBus->session;
$ybus = Net::DBus->system;

$esrv = $ebus->get_service("org.freedesktop.PackageKit");
#print dbus_dump($esrv);
$ysrv = $ybus->get_service("org.freedesktop.PackageKit");
#print dbus_dump($ysrv);
$eobj = $esrv->get_object("/org/freedesktop/PackageKit");
#print dbus_dump($eobj);
$yobj = $ysrv->get_object("/org/freedesktop/PackageKit");
#print dbus_dump($yobj);

my $tid = $yobj->GetTid;
print "tid: $tid\n";

my $trans = $ysrv->get_object($tid);
#print dbus_dump($trans);

my $sigid = $trans->connect_to_signal("Package",sub {
	my ($info,$package_id,$summary) = @_;
	print "info: $info\n";
	print "package_id: $package_id\n";
	print "summary: $summary\n";
}) or die "can't connect to signal";

#$trans->GetDetails(['packagekit;0.7.6-2;i686;community']);
#$trans->GetCategories;
$trans->GetUpdates('installed');
#print dbus_dump($trans);
#my $props = $trans->GetAll("org.freedesktop.PackageKit.Transaction");
#foreach my $k (keys %$props) {
#	print "$k: ", $props->{$k}, "\n";
#}

$reactor->run();

$trans->disconnect_from_signal($sigid);
