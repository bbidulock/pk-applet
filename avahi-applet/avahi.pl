#!/usr/bin/perl

use Net::DBus;
use Net::DBus::Dumper;
use Net::DBus::Reactor;
use GDBM_File;
use Net::Libdnet::Intf;
use Net::Libdnet::Entry::Intf;
use Data::Dumper;

my $Intf = Net::Libdnet::Intf->new;

sub each_intf {
	my ($intf,$interfaces) = @_;
	my $i = Net::Libdnet::Entry::Intf->newFromHash($intf);
	print $i->print, "\n";
	push @$interfaces,$i->name;
}

sub get_interfaces {
	my $interfaces = [];
	$Intf->loop('main::each_intf',$interfaces);
	return @$interfaces;
}

my @interfaces = (get_interfaces);

my $reactor = Net::DBus::Reactor->main();

my ($bus,$srv,$obj);

$bus = Net::DBus->system;
$srv = $bus->get_service("org.freedesktop.Avahi");
print dbus_dump($srv);
$obj = $srv->get_object("/");
print dbus_dump($obj);
print "Version: ", $obj->GetVersionString, "\n";
print "API Version: ", $obj->GetAPIVersion, "\n";
print "Hostname: ", $obj->GetHostName, "\n";
print "Domainname: ", $obj->GetDomainName, "\n";
print "FQDN: ", $obj->GetHostNameFqdn, "\n";
print "NSS Support: ", $obj->IsNSSSupportAvailable, "\n";
print "State: ", $obj->GetState, "\n";
print "Cookie: ", $obj->GetLocalServiceCookie, "\n";
#my $path = $obj->EntryGroupNew;
#print "Path: $path\n";
#my $grp = $srv->get_object($path);
#print dbus_dump($grp);

my %stypes = ();

domain_browser($obj,$srv);
service_type_browser($obj,$srv,\%stypes);
foreach my $type (sort keys %stypes) {
	service_browser($obj,$srv,$type);
}
#record_browser($obj,$srv);
#foreach my $type (sort keys %stypes) {
#	service_resolver($obj,$srv,$type);
#}

sub domain_browser {
	my ($server,$service) = @_;
	my $path = $server->DomainBrowserNew(-1,-1,"",0,0);
	my $obj = $service->get_object($path);
	print dbus_dump($obj);

	my $sig1 = $obj->connect_to_signal("AllForNow",sub {
		print "All for now...\n";
		$reactor->shutdown;
	});
	my $sig2 = $obj->connect_to_signal("CacheExhausted",sub {
		print "Cache exhausted...\n";
	});
	my $sig3 = $obj->connect_to_signal("Failure",sub {
		my ($err) = @_;
		print "Failure: $err\n";
		$reactor->shutdown;
	});
	my $sig4 = $obj->connect_to_signal("ItemNew",sub {
		my ($interface,$protocol,$domain,$flags) = @_;
		print "Item new: \n";
		print "  Interface: $interface\n";
		print "  Protocol: $protocol\n";
		print "  Domain: $domain\n";
		print "  Flags: $flags\n";
	});
	my $sig5 = $obj->connect_to_signal("ItemRemove",sub {
		my ($interface,$protocol,$domain,$flags) = @_;
		print "Item remove: \n";
		print "  Interface: $interface\n";
		print "  Protocol: $protocol\n";
		print "  Domain: $domain\n";
		print "  Flags: $flags\n";
	});

	$reactor->run;
	$obj->Free;
}

sub service_type_browser {
	my ($server,$service,$stypes) = @_;
	my $path = $server->ServiceTypeBrowserNew(-1,1,"",0);
	my $obj = $service->get_object($path);
	print dbus_dump($obj);

	my $sig1 = $obj->connect_to_signal("AllForNow",sub {
		print "All for now...\n";
		$reactor->shutdown;
	});
	my $sig2 = $obj->connect_to_signal("CacheExhausted",sub {
		print "Cache exhausted...\n";
	});
	my $sig3 = $obj->connect_to_signal("Failure",sub {
		my ($err) = @_;
		print "Failure: $err\n";
		$reactor->shutdown;
	});
	my $sig4 = $obj->connect_to_signal("ItemNew",sub {
		my ($interface,$protocol,$type,$domain,$flags) = @_;
		my $iname = $server->GetNetworkInterfaceNameByIndex($interface);
		print "Item new: \n";
		print "  Interface: $interface ($iname)\n";
		print "  Protocol: $protocol\n";
		print "  Type: $type\n";
		print "  Domain: $domain\n";
		print "  Flags: $flags\n";
		$stypes->{$type} = 1;
	});
	my $sig5 = $obj->connect_to_signal("ItemRemove",sub {
		my ($interface,$protocol,$type,$domain,$flags) = @_;
		my $iname = $server->GetNetworkInterfaceNameByIndex($interface);
		print "Item remove: \n";
		print "  Interface: $interface ($iname)\n";
		print "  Type: $type\n";
		print "  Domain: $domain\n";
		print "  Flags: $flags\n";
	});

	$reactor->run;
	$obj->Free;
}

sub service_browser {
	my ($server,$service,$type) = @_;
	my $path = $server->ServiceBrowserNew(-1,-1,$type,"",0);
	my $obj = $service->get_object($path);
	print dbus_dump($obj);

	my $sig1 = $obj->connect_to_signal("AllForNow",sub {
		print "All for now...\n";
		$reactor->shutdown;
	});
	my $sig2 = $obj->connect_to_signal("CacheExhausted",sub {
		print "Cache exhausted...\n";
	});
	my $sig3 = $obj->connect_to_signal("Failure",sub {
		my ($err) = @_;
		print "Failure: $err\n";
		$reactor->shutdown;
	});

	my %desc = ();
	tie my %file, 'GDBM_File', './service-types.db', &GDBM_READER, 0644;
	while (my ($key,$val) = each %file) {
		$desc{$key} = $val;
	}
	untie %file;
	my $sig4 = $obj->connect_to_signal("ItemNew",sub {
		my ($interface,$protocol,$name,$type,$domain,$flags) = @_;
		my $iname = $server->GetNetworkInterfaceNameByIndex($interface);
		print "Item new: \n";
		print "  Interface: $interface ($iname)\n";
		print "  Protocol: $protocol\n";
		print "  Name: $name\n";
		print "  Type: $type\n";
		print "  Description: ",$desc{$type}, "\n";
		print "  Domain: $domain\n";
		print "  Flags: $flags\n";
#		my $aname = $server->GetAlternativeServiceName($name);
#		print "  Alternate service name: $aname\n";
		my @result = $server->ResolveService($interface,$protocol,$name,$type,$domain,1,0);
		print "Resolved item: \n";
		print "  Interface: $result[0]\n";
		print "  Protocol: $result[1]\n";
		print "  Name: $result[2]\n";
		print "  Type: $result[3]\n";
		print "  Description: ",$desc{$result[3]}, "\n";
		print "  Domain: $result[4]\n";
		print "  Host: $result[5]\n";
		print "  Aprotocol: $result[6]\n";
		print "  Address: $result[7]\n";
		print "  Port: $result[8]\n";
		print "  TXT: ",join(';',map {pack('U*',@$_)} @{$result[9]}),"\n";
		print "  Flags: $result[10]\n";
	});
	my $sig5 = $obj->connect_to_signal("ItemRemove",sub {
		my ($interface,$protocol,$name,$type,$domain,$flags) = @_;
		my $iname = $server->GetNetworkInterfaceNameByIndex($interface);
		print "Item remove: \n";
		print "  Interface: $interface ($iname)\n";
		print "  Name: $name\n";
		print "  Type: $type\n";
		print "  Description: ",$desc{$type}, "\n";
		print "  Domain: $domain\n";
		print "  Flags: $flags\n";
	});

	$reactor->run;
	$obj->Free;
}

sub record_browser {
	my ($server,$service) = @_;
	my $path = $server->RecordBrowserNew(-1,-1,"",1,1,0);
	my $obj = $service->get_object($path);
	print dbus_dump($obj);

	my $sig1 = $obj->connect_to_signal("AllForNow",sub {
		print "All for now...\n";
		$reactor->shutdown;
		$obj->Free;
	});
	my $sig2 = $obj->connect_to_signal("CacheExhausted",sub {
		print "Cache exhausted...\n";
	});
	my $sig3 = $obj->connect_to_signal("Failure",sub {
		my ($err) = @_;
		print "Failure: $err\n";
		$reactor->shutdown;
		$obj->Free;
	});

	my $sig4 = $obj->connect_to_signal("ItemNew",sub {
		my ($interface,$protocol,$name,$class,$type,$rdata,$flags) = @_;
		print "Item new: \n";
		print "  Interface: $interface\n";
		print "  Protocol: $protocol\n";
		print "  Name: $name\n";
		print "  Class: $class\n";
		print "  Type: $type\n";
		print "  Rdata: ",join(':',@$rdata),"\n";
		print "  Flags: $flags\n";
	});
	my $sig5 = $obj->connect_to_signal("ItemRemove",sub {
		my ($interface,$protocol,$name,$class,$type,$rdata,$flags) = @_;
		print "Item remove: \n";
		print "  Interface: $interface\n";
		print "  Name: $name\n";
		print "  Class: $class\n";
		print "  Type: $type\n";
		print "  Rdata: ",join(':',@$rdata),"\n";
		print "  Flags: $flags\n";
	});

	$reactor->run;
}

sub service_resolver {
	my ($server,$service,$type) = @_;
	my $path = $server->ServiceResolverNew(-1,-1,"",$type,"",0,0);
	my $obj = $service->get_object($path);
	print dbus_dump($obj);

	my $sig1 = $obj->connect_to_signal("Failure",sub {
		my ($err) = @_;
		print "Failure: $err\n";
		$reactor->shutdown;
	});
	my $sig2 = $obj->connect_to_signal("Found",sub {
		my ($interface,$protocol,$name,$type,$domain,$host,$aprotocol,$address,$port,$txt,$flags) = @_;
		my $iname = $server->GetNetworkInterfaceNameByIndex($interface);
		print "Found: \n";
		print "  Interface: $interface ($iname)\n";
		print "  Protocol: $protocol\n";
		print "  Name: $name\n";
		print "  Type: $type\n";
		print "  Domain: $domain\n";
		print "  Host: $host\n";
		print "  Aprotocol: $aprotocol\n";
		print "  Address: $address\n";
		print "  Port: $port\n";
		print "  TXT: ",join(';',map {pack('U*',@$_)} @$txt),"\n";
		print "  Flags: $flags\n";
		$reactor->shutdown;
	});
	$reactor->run;
	$obj->Free;
}
