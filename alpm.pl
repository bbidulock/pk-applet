#!/usr/bin/perl

# playing with ALPM module

use strict;
use warnings;
use ALPM;
my $alpm = ALPM->new('/', '/var/lib/pacman');
$alpm->set_cachedirs('/var/cache/pacman/pkg');
$alpm->set_logfile('/u2/dbus/pacman.log');

$alpm->register('custom');
$alpm->register('core');
$alpm->register('extra');
$alpm->register('community');

#use ALPM::Conf;
#
#my $conf = ALPM::Conf->new('/etc/pacman.conf');
#my $alpm = $conf->parse;

# find all packages?

sub struct_expand {
	my $val = shift;
	if (ref($val) eq 'ARRAY') {
		return '['.join(',', map {struct_expand($_)} @$val).']';
	}
	elsif (ref($val) eq 'HASH') {
		return '{'.join(',', map {$_.'=>'.struct_expand($val->{$_})} keys %$val).'}';
	}
	elsif (ref($val) eq 'ALPM::DB') {
		return $val->name;
	}
	return $val;
}

if (0) {
foreach my $pkg ($alpm->search('perl')) {
	foreach my $sub ('filename', 'name', 'version', 'desc', 'url', 'builddate', 'installdate',
			 'packager', 'arch', 'size', 'isize', 'reason', 'licenses', 'groups',
			 'depends', 'optdepends', 'conflicts', 'provides', 'deltas', 'replaces',
			 'files', 'backup', 'has_scriptlet', 'download_size', 'changelog',
			 'requiredby', 'db', 'checkmd5sum') {
		next unless $pkg->can($sub);
		next if $sub =~ /^(backup|provides|conflicts|replaces)$/;
		my $val = $pkg->$sub;
		next unless defined $val;
		if ($sub eq 'depends' or $sub eq 'files') {
			my @fields = ();
			foreach my $hashref (@$val) {
				push @fields,'{'.join(',',map {defined($hashref->{$_})?$_.'=>'.$hashref->{$_}:()} keys %$hashref).'}';
			}
			$val = join("\n\t",@fields);
		}
		elsif (ref($val) eq 'ALPM::DB') {
			$val = $val->name;
		}
		elsif (ref($val) eq 'ARRAY') {
			$val = join("\n\t",@$val);
		}
		#$val = struct_expand($val);
		print "$sub: ",$val,"\n";
	}
}
}

my $fh;
my %groups = ();

sub readem {
	my $fh = shift;
	while (<$fh>) {
		chomp; chomp;
		my ($group,$pkg) = split(/\s/,$_);
		if (defined $pkg) {
			$groups{$group}{$pkg} = 1;
		} else {
			$groups{$group} = {} unless exists $groups{$group};
		}
	}
}

open($fh, "pacman -Qg |");
readem($fh);
close($fh);
open($fh, "pacman -Sg |");
readem($fh);
close($fh);

foreach my $group (sort keys %groups) {
	my @pkgs = sort keys %{$groups{$group}};
	print "  Group: $group\n";
	foreach my $pkg (@pkgs) {
		print "    Package: $pkg\n";
	}
}

foreach my $db ($alpm->dbs) {
	print "Database: ",$db->name,"\n";
	foreach my $group (sort keys %groups) {
		print "  Group: $group\n";
		my @pkgs = $db->find_group($group);
		foreach my $pkg (map {$_->name} @pkgs) {
			$groups{$group}{$pkg} = 1;
		}
	}
}

foreach my $group (sort keys %groups) {
	my @pkgs = sort keys %{$groups{$group}};
	print "  Group: $group\n";
	foreach my $pkg (@pkgs) {
		print "    Package: $pkg\n";
	}
}

print "Groups:\n";
foreach my $group (sort keys %groups) {
	print "  Group: $group\n";
}

if (0) {
foreach my $db ($alpm->dbs) {
	print "Database: ",$db->name,"\n";
	print  "(getting groups...)\n";
	my %groups = $db->groups;
	print  "(sorting keys...)\n";
	foreach my $group (sort keys %groups) {
		my @pkgs = @{$groups{$group}};
		print "  Group: $group\n";
		foreach my $pkg (@pkgs) {
			print "    Package: $pkg\n";
		}
	}
}
}

