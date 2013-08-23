#!/usr/bin/perl

use strict;
use warnings;

# read pacman repos directly

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


my $pacdir = "/var/lib/pacman";
my $localdir = "$pacdir/local";
my $syncdir  = "$pacdir/sync";

my $fh;

sub read_files {
	my ($fh,$dbname,$dir) = @_;
	my $data = {};
STANZA:	while (<$fh>) { chomp; chomp;
		if (/^%([A-Z][A-Z0-9]*)%$/) {
			my $tag = $1;
			$data->{$tag} = [];
			while (<$fh>) { chomp; chomp;
				next STANZA if /^\s*$/;
				push @{$data->{$tag}}, $_;
			}
		}
		elsif (/^\s*$/) {
			next;
		}
		else {
			print STDERR "Garbage in input stream! $_\n";
			next;
		}
		print STDERR "Unexpected end of input! db: $dbname dir: $dir\n";
		return $data;
	}
	return $data;
}

sub process_data {
	my ($dbname,$dir,$data) = @_;
	print ">>>>>>>>>>>>>>>>\n";
	foreach my $tag ('FILENAME', 'NAME', 'BASE', 'VERSION', 'DESC',
			 'GROUPS', 'CSIZE', 'ISIZE', 'MD5SUM', 'SHA256SUM',
			 'PGPSIG', 'URL', 'LICENSE', 'ARCH', 'BUILDDATE',
			 'PACKAGER', 'REPLACES', 'DEPENDS', 'CONFLICTS',
			 'PROVIDES', 'OPTDEPENDS', 'FILES', 'DELTAS')
	{
		print "$tag: ",join(';',@{$data->{$tag}}),"\n" if exists $data->{$tag};
	}
}

{
	my $dbname = 'local';
	print STDERR ">>>> Processing db: local\n";
	my %fnames = ();
	if ( open($fh, "find $localdir -type f |") ) {
		while (<$fh>) { chomp; chomp;
			s{^$localdir/}{};
			my @parts = split(/\//,$_);
			next unless @parts >= 2;
			my ($dir,$file) = ($parts[-2],$parts[-1]);
			if ($file =~ /^(desc|depends|files|deltas)$/) {
				$fnames{$dbname}{$dir}{$file} = 1
			} else {
				print STDERR "Wrong file name $file\n"
				unless $file eq 'install';
			}
		}
		close($fh);
	}
#	print STDERR "  >> Processing files...\n";
	foreach my $dir (sort keys %{$fnames{$dbname}}) {
		my @names = keys %{$fnames{$dbname}{$dir}};
		next unless @names;
		my @files = map {"$localdir/$dir/$_"} @names;
		my $cmd = "cat ".join(' ',@files);
#		print STDERR "   > Executing command $cmd...\n";
		if ( open($fh, "$cmd |") ) {
			my $data = read_files($fh,$dbname,$dir);
#			process_data($dbname,$dir,$data);
			close($fh);
		}
	}
}

my @dbs = ();
if ( open($fh, "find $syncdir -type f -name '*.db' |") ) {
	while (<$fh>) { chomp; chomp;
		push @dbs, $_;
	}
	close($fh);
}

foreach my $db (@dbs) {
	print STDERR ">>>> Processing db: $db\n";
	my $dbname = (split(/\//,$db))[-1]; $dbname =~ s/\.db$//;
	my %fnames = ();
	if (1) {
		my $tmpdir = "/tmp/$dbname";
#		print STDERR "  >> Unpacking files...\n";
		system("mkdir -p $tmpdir");
		system("tar -xf $db -C $tmpdir");
		if ( open($fh, "find $tmpdir -type f |") ) {
			while (<$fh>) { chomp; chomp;
				s{^$tmpdir/}{};
				my @parts = split(/\//,$_);
				next unless @parts >= 2;
				my ($dir,$file) = ($parts[-2],$parts[-1]);
				if ($file =~ /^(desc|depends|files|deltas)$/) {
					$fnames{$dbname}{$dir}{$file} = 1
				} else {
					print STDERR "Wrong file name $file\n"
					unless $file eq 'install';
				}
			}
			close($fh);
		}
#		print STDERR "  >> Processing files...\n";
		foreach my $dir (sort keys %{$fnames{$dbname}}) {
			my @names = keys %{$fnames{$dbname}{$dir}};
			next unless @names;
			my @files = map {"$tmpdir/$dir/$_"} @names;
			my $cmd = "cat ".join(' ',@files);
#			print STDERR "   > Executing command $cmd...\n";
			if ( open($fh, "$cmd |") ) {
				my $data = read_files($fh,$dbname,$dir);
#				process_data($dbname,$dir,$data);
				close($fh);
			}
		}
		system("rm -fr $tmpdir");
	} else {
		if ( open($fh, "tar tf $db |") ) {
			while (<$fh>) { chomp; chomp;
				my @parts = split(/\//,$_);
				next unless @parts >= 2;
				my ($dir,$file) = ($parts[-2],$parts[-1]);
				if ($file =~ /^(desc|depends|files|deltas)$/) {
					$fnames{$dbname}{$dir}{$file} = 1
				} else {
					print STDERR "Wrong file name $file\n"
					unless $file eq 'install';
				}
			}
			close($fh);
		}
#		print STDERR "  >> Processing files lists...\n";
		foreach my $dir (sort keys %{$fnames{$dbname}}) {
#			print STDERR "   > Processing directory $dir...\n";
			my @names = keys %{$fnames{$dbname}{$dir}};
			next unless @names;
			my @paths = map {"$dir/$_"} @names;
			my $cmd = "tar xOf $db ".join(' ',@paths);
#			print STDERR "   > Executing command $cmd...\n";
			if ( open($fh, "$cmd |") ) {
				my $data = read_files($fh,$dbname,$dir);
#				process_data($dbname,$dir,$data);
				close($fh);
			}
		}
	}
}

