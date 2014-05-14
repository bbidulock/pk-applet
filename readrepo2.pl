#!/usr/bin/perl

use strict;
use warnings;

# /desc file has
#   %FILENAME%
#   %NAME%
#   %BASE%
#   %VERSION%
#   %DESC%
#   %GROUPS%
#   %CSIZE%
#   %ISIZE%
#   %MD5SUM%
#   %SHA256SUM%
#   %PGPSIG%
#   %URL%
#   %LICENSE%
#   %ARCH%
#   %BUILDDATE%
#   %PACKAGER%
#   %REPLACES%
#
# /depends file has
#   %DEPENDS%
#   %CONFLICTS%
#   %PROVIDES%
#   %OPTDEPENDS%
#
# /files file has
#   %FILES%
#   just a list of files with no leading /
#
# /deltas file has
#   %DELTAS%
#   delta-pkg(ends in .delta) checksum size to-pkg from-pkg
#
# In the local database /depends gets sucked into /desc and
# /deltas is discarded; /files is kept
#
# one more kick at the can
# 
# Just process the desc files for speed.  The local repository concatenates
# local 'depend' files into 'desc' files anyway.  Remote depend files are
# less important.

my $pacdir = "/var/lib/pacman";
my $localdir = "$pacdir/local";
my $syncdir  = "$pacdir/sync";
my $cachedir = "/var/cache/pacman/pkg";

my $fh;

if (0) {
my @files = map{chomp;$_} `find $localdir -type f -name 'desc'`;
for (@files) {
	print "File: $_\n";
}

my @dbs = map{chomp;$_} `find $syncdir -type f -name '*.db'`;
for (@dbs) {
	print "Databases: $_\n";
}
}

sub package_id {
	my ($db,$data) = @_;
	return "$data->{name};$data->{version};$data->{arch};$db";
}

my $count = 0;

sub read_files {
	my ($pkgs,$db,$cmd) = @_;
	my $data = {};
	if (open(my $fh,$cmd)) {
STANZA:		while (<$fh>) { chomp;
			if (/^%FILENAME%$/) {
				if (exists $data->{name} and $data->{name}) {
					my $id = package_id($db,$data);
					$pkgs->{$id} = $data;
					$count++;
				}
				$data = {};
			}
			if (/^%([A-Z][A-Z0-9]*)%$/) {
				my $tag = "\L$1\E";
				$data->{$tag} = []
					unless exists $data->{$tag};
				while (<$fh>) { chomp;
					next STANZA if /^\s*$/;
					push @{$data->{$tag}}, $_;
				}
			}
			elsif (/^\s*$/) {
				next;
			}
			else {
				print STDERR "Garbage in input stream! '$_'\n";
				next;
			}
			print STDERR "Unexpected end of input!\n";
		}
		close($fh);
	}
	return $pkgs;
}

sub read_info {
	my ($pkgs,$db,$cmd) = @_;
	my $data = {};
	if (open(my $fh,$cmd)) {
		while (<$fh>) { chomp;
			if (/^pkgname = /) {
				if (exists $data->{name} and $data->{name}) {
					my $id = package_id($db,$data);
					$pkgs->{$id} = $data;
					$count++;
				}
				$data = {};
			}
			if (/^pkg([a-z]*) = (.*)$/) {
				my $tag = $1;
				$tag = 'version' if $tag eq 'ver';
				push @{$data->{$tag}},$2;
				next;
			}
			elsif (/^([a-z][a-z0-9]*) = (.*)$/) {
				my $tag = $1;
				$tag .= 's' if $tag =~ /(depend|conflict|optdepend)/;
				$tag = 'isize' if $tag eq 'size';
				push @{$data->{$tag}},$2;
				next;
			}
			elsif (/^#/) {
				next;
			}
			else {
				print STDERR "Garbage in input stream!  '$_'\n";
				next;
			}
			print STDERR "Unexpected end of input!\n";
		}
		close($fh);
	}
}

my $pkgs = {};
my $cmd;
my @dbs = map{chomp;$_} `find $syncdir -type f -name '*.db'`:
for (@dbs) {
	$cmd = "tar xzOf $_ --wildcards --no-wildcards-match-slash '*/desc' |";
	my $db = $_; $db =~ s/^.*\///; $db =~ s/\.db$//;
	read_files($pkgs,$db,$cmd);
}
$cmd = "find $localdir -type f -name desc|xargs cat |";
read_files($pkgs,'installed',$cmd);


if (0) {
sub read_files_files {
	my ($pkgs,$db,$cmd,$files) = @_;
	my @files = ();
	if (open(my $fh,$cmd)) {
		close($fh);
	}
}

for (@dbs) {
	my @files = map{chomp;$_} `tar tzf $_ --wildcards --no-wildcards-match-slash '*/files'`;
	$cmd = "tar xzOf $_ --wildcards --no-wildcards-match-slash '*/files' |";
	my $db = $_; $db =~ s/^.*\///; $db =~ s/\.db$//;
	read_files_files($pkgs,$db,$cmd,\@files);
}
}


if (0) {
# too freaking slow
my @pkg = map{chomp;$_} `find $cachedir -type f -name '*.pkg.tar.*'`;
for (@pkg) {
	$cmd = "bsdtar xJOf $_ .PKGINFO |";
	print "Reading $_\n";
	read_info($pkgs,'local',$cmd);
}
}

print STDERR "Created $count packages...\n";
exit(0);
foreach my $id (sort keys %$pkgs) {
	my $data = $pkgs->{$id};
	foreach my $key ('filename', 'name', 'base', 'version', 'desc',
			'groups', 'csize', 'isize', 'md5sum', 'sha256sum',
			'pgpsig', 'url', 'license', 'arch', 'builddate',
			'packager', 'replaces', 'depends', 'conflicts',
			'provides', 'optdepends') {
		print "$key: ",join(';',@{$data->{$key}}),"\n"
			if exists $data->{$key};
	}
}

