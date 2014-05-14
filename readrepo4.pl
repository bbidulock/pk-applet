#!/usr/bin/perl

use strict;
use warnings;

use Archive::Tar;
use Archive::Tar::File;

my $pacdir = "/var/lib/pacman";
my $localdir = "$pacdir/local";
my $syncdir  = "$pacdir/sync";
my $cachedir = "/var/cache/pacman/pkg";

sub read_content {
	my ($pkgs,$name,$cref) = @_;
	 # print "Reading file $name\n";
	if (open(my $fh, '<', $cref)) {
		my @parts = split(/\//,$name);
		my ($pkg,$mode) = ($parts[-2],$parts[-1]);
		$pkg =~ /^(.*)-([^-]*-[^-]*)$/;
		my $id = "$1;$2";
		$pkgs->{$id} = {} unless exists $pkgs->{$id};
		my $data = $pkgs->{$id};
	STANZA:	while (<$fh>) { s/\n//;
			if (/^%([A-Z][A-Z0-9]*)%/) {
				my $tag = "\L$1\E";
				$data->{$tag} = [] unless exists $data->{$tag};
				while (<$fh>) { s/\n//;
					next STANZA if /^\s*$/;
					push @{$data->{$tag}}, $_;
				}
				# print STDERR "Unexpeced end of input!\n";
				last;
			}
			elsif (/^\s*$/) {
				next;
			}
			else {
				print STDERR "Garbage in input stream!\n";
			}
		}
		close($fh);
	}
}

sub read_databases {
	my $pkgs = shift;
	my @dbs = map{chomp;$_} `find $syncdir -type f -name '*.db'`;
	foreach my $db (@dbs) {
		my $tar = Archive::Tar->new;
		my @files = $tar->read($db,undef,{
			filter=>'/(desc|depends|files|deltas)$',
		});
		my $dbname = $db; $dbname =~ s/^.*\///; $dbname =~ s/\.db$//;
		$pkgs->{$dbname} = {} unless exists $pkgs->{$dbname};
		my $mypkgs = $pkgs->{$dbname};
		foreach my $f (@files) {
			my $data = delete $f->{data};
			read_content($mypkgs,$f->name,\$data);
		}
	}
}

sub read_files {
	my $pkgs = shift;
	my @files = map{chomp;$_} `find $localdir -type f -name desc -o -name files 2>/dev/null`;
	my $dbname = 'local';
	$pkgs->{$dbname} = {} unless exists $pkgs->{$dbname};
	my $mypkgs = $pkgs->{$dbname};
	foreach my $file (@files) {
		read_content($mypkgs,$file,$file);
	}
}

my $pkgs = {};

read_databases($pkgs);
if (0) {
read_files($pkgs);
}
