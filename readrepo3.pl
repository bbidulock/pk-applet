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

# local /desc files have:
#   %ARCH%
#   %BUILDDATE%
#   %CONFLICTS%		(used to be in a /depends file)
#   %DEPENDS%		(used to be in a /depends file)
#   %DESC%
#   %GROUPS%
#   %INSTALLDATE%	<------------
#   %LICENSE%
#   %NAME%
#   %OPTDEPENDS%	(used to be in a /depends file)
#   %PACKAGER%
#   %PROVIDES%		(used to be in a /depends file)
#   %REASON%		<------------ 1 (dependency) missing (explicit)
#   %REPLACES%
#   %SIZE%		<------------ Installed size
#   %URL%
#   %VERSION%

# local /files files have:
#   %BACKUP%		<------------ filename tab MD5 checksum
#   %FILES%

# sync /desc files have
#   %ARCH%
#   %BASE%		<------------ source package name
#   %BUILDDATE%
#   %CSIZE%		<------------ compressed size
#   %DESC%
#   %FILENAME%		<------------ filename to download from repository
#   %GROUPS%
#   %ISIZE%		<------------ installed size
#   %LICENSE%
#   %MD5SUM%		<------------ MD5 checksum of download file
#   %NAME%
#   %PACKAGER%
#   %PGPSIG%		<------------ PGP signature of download file
#   %REPLACES%
#   %SHA256SUM%		<------------ SHA-256 checksum of download file
#   %URL%
#   %VERSION%

# sync /depends files have
#   %CONFLICTS%
#   %DEPENDS%
#   %OPTDEPENDS%
#   %PROVIDES%

# sync /files files have
#   %FILES%

# sync /deltas files have
#   %DELTAS%	    <------------ deltas (from /deltas file) usually missing
my $pacdir = "/var/lib/pacman";
my $localdir = "$pacdir/local";
my $syncdir  = "$pacdir/sync";
my $cachedir = "/var/cache/pacman/pkg";

sub read_files {
	my $pkgs = shift;
	my $count = 0;
	my @files = map{chomp;$_} `find $localdir -type f -name desc -o -name files 2>/dev/null`;
	foreach my $file (@files) {
		if (open (my $fh, "<$file")) { $count++;
			my @parts = split(/\//,$file);
			my ($pkg,$mode) = ($parts[-2],$parts[-1]);
			$pkg =~ /^(.*)-([^-]*-[^-]*)$/;
			my $id = "$1;$2";
			$pkgs->{$id} = {} unless exists $pkgs->{$id};
			my $data = $pkgs->{$id};
STANZA:			while (<$fh>) {
				if (/^%([A-Z][A-Z0-9]*)%/) {
					my $tag = "\L$1\E";
					$data->{$tag} = [] unless exists $data->{$tag};
					while (<$fh>) { chop;
						next STANZA if /^\s*$/;
						push @{$data->{$tag}}, $_;
					}
					print STDERR "Unexpeced end of input!\n";
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
	return $count;
}

sub read_database {
	my ($pkgs,$cmd1,$cmd2) = @_;
	my $count = 0;
	open (my $fh1,$cmd1) or return $count;
	open (my $fh2,$cmd2) or return $count;
	my ($modechange,$file,$pkg,$id,$mode,$state,$data) = (1);
STANZA:	while (<$fh2>) { s/\n//;
		if (/^%([A-Z][A-Z0-9]*)%/) {
			my $tag = "\L$1\E";
			 # print "New tag=$tag\n";
		RESTART:
			if ($modechange) {
				# changing mode
				$count++ if $id;
				$file = <$fh1>;
				last STANZA unless defined $file;
				$file =~ s/\n//;
				($pkg,$mode) = split(/\//,$file);
				$pkg =~ /^(.*)-([^-]*-[^-]*)$/;
				$id = "$1;$2";
				$pkgs->{$id} = {} unless exists $pkgs->{$id};
				$data = $pkgs->{$id};
				 # print "Starting file=$file id=$id mode=$mode\n";
				$state = undef;
				$modechange = undef;
			}
			if ($state) {
				if ($mode eq 'desc') {
					if ($tag =~ /^(filename|depends|conflicts|provides|optdepends|files|deltas)$/) {
						$modechange = 1;
						goto RESTART;
					}
				}
				elsif ($mode eq 'depends') {
					# order is:
					#  %DEPENDS%
					#  %CONFLICTS%
					#  %PROVIDES%
					#  %OPTDEPENDS%
					unless ($tag =~ /^(conflicts|provides|optdepends)$/) {
						$modechange = 1;
						goto RESTART;
					}
					if ($state eq 'depends') {
						unless ($tag =~ /^(conflicts|provides|optdepends)$/) {
							$modechange = 1;
							goto RESTART;
						}
					}
					elsif ($state eq 'conflicts') {
						unless ($tag =~ /^(provides|optdepends)$/) {
							$modechange = 1;
							goto RESTART;
						}
					}
					elsif ($state eq 'provides') {
						unless ($tag =~ /^(optdepends)$/) {
							$modechange = 1;
							goto RESTART;
						}
					}
					elsif ($state eq 'optdepends') {
						$modechange = 1;
						goto RESTART;
					}
					$state = $tag;
				}
				else {
					$modechange = 1;
					goto RESTART;
				}
#				elsif ($mode eq 'files') {
#					$modechange = 1;
#					goto RESTART;
#				}
#				elsif ($mode eq 'deltas') {
#					$modechange = 1;
#					goto RESTART;
#				}
			} else {
				if ($mode eq 'desc') {
					unless ($tag eq 'filename') {
						print STDERR "Lost sync! mode=$mode, tag=$tag, file=$file, id=$id\n";
						last STANZA;
					}
				}
				elsif ($mode eq 'depends') {
					unless ($tag =~ /^(depends|conflicts|optdepends|provides)$/) {
						# file can be empty?
						$modechange = 1;
						goto RESTART;
					}
				}
				elsif ($mode ne $tag) {
					$modechange = 1;
					goto RESTART;
				}
#				elsif ($mode eq 'files') {
#					unless ($tag eq 'files') {
#						# file can be empty?
#						$modechange = 1;
#						goto RESTART;
#					}
#				}
#				elsif ($mode eq 'deltas') {
#					unless ($tag eq 'deltas') {
#						# file can be empty?
#						$modechange = 1;
#						goto RESTART;
#					}
#				}
				$state = $tag;
			}
			 # print "Starting reading $tag\n";
			$data->{$tag} = [] unless exists $data->{$tag};
			while (<$fh2>) { s/\n//;
				if (/^\s*$/) {
					 # print "Finished reading $tag\n";
					next STANZA;
				}
				if (/^%([A-Z][A-Z0-9]*)%/) {
					 # some file miss the blank line
					$tag = "\L$1\E";
					goto RESTART;
				}
				push @{$data->{$tag}}, $_;
			}
			 # print STDERR "Unexpected end of input! '$_' mode=$mode state=$state\n";
		}
		elsif (/^\s*$/) {
			next;
		}
		else {
			print STDERR "Garbage in input stream! '$_' mode=$mode state=$state\n";
			next;
		}
	}
	close($fh2);
	close($fh1);
	return $count;
}


my $pkgs = {};

{
	$pkgs->{local} = {};
	my $count = read_files($pkgs->{local});
	print "Read $count package files from local\n";
}

my @dbs = map{chomp;$_} `find $syncdir -type f -name '*.db'`;
for (@dbs) {
	my $db = $_; $db =~ s/^.*\///; $db =~ s/\.db$//;
	my $cmd1 = "tar tzf  $_ --ignore-failed-read --wildcards --no-wildcards-match-slash '*/desc' '*/files' '*/depends' '*/deltas' 2>/dev/null |";
	my $cmd2 = "tar xzOf $_ --ignore-failed-read --wildcards --no-wildcards-match-slash '*/desc' '*/files' '*/depends' '*/deltas' 2>/dev/null |";
	$pkgs->{$db} = {};
	my $count = read_database($pkgs->{$db},$cmd1,$cmd2);
	print "Read $count package files from $db\n";
}


exit(0);

foreach my $db (sort keys %$pkgs) {
	my $db_data = $pkgs->{$db};
	foreach my $namver (sort keys %$db_data) {
		my $hash = $db_data->{$namver};
		my ($name,$version) = split(/;/,$namver);
		$hash->{db}[0] = $db;
		if ($hash->{name}[0] ne $name) {
			print STDERR "Names $name and $hash->{name} do not match!\n";
		}
		if ($hash->{version}[0] ne $version) {
			print STDERR "Versions $version and $hash->{version} do not match!\n";
		}
		my $arch = $hash->{arch}[0];
		my $source = $db;
		$source = 'installed' if $db eq 'local';
		$hash->{source}[0] = $source;
		my $id = "$name;$version;$arch;$source";
		$hash->{id}[0] = $id;
		$hash->{package_id}[0] = $id;
		my $summary = $hash->{desc}[0];
		$summary = substr($summary,0,80).'...' if length($summary) > 83;
		$hash->{summary}[0] = $summary;
		my $info = $db eq 'local' ? 'installed' : 'available';
		$hash->{info}[0] = $info;
		print "id = $id\n";
		if ($db eq 'local') {
			foreach my $field (qw/package_id info name version desc summary groups url
			license arch builddate packager replaces depends conflicts provides
			optdepends size reason backup files/)
			{
				if (exists $hash->{$field} and defined $hash->{$field}) {
					print "    $field = ", join(';',@{$hash->{$field}}), "\n";
				} else {
					print "    $field = ", "\n";
				}
			}
		} else {
			foreach my $field (qw/package_id info filename name base version desc
			summary groups csize isize md5sum sha256sum pgpsig url license arch
			builddate packager replaces depends conflicts provides optdepends files
			deltas/)
			{
				if (exists $hash->{$field} and defined $hash->{$field}) {
					print "    $field = ", join(';',@{$hash->{$field}}), "\n";
				} else {
					print "    $field = ", "\n";
				}
			}
		}
	}
}
