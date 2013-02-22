#!/usr/bin/perl

my $fn = shift;

use DB_File;

tie %file, 'DB_File', $fn, O_RDONLY, 0644, $DB_HASH or die $!;
while (my ($key,$val) = each %file) {
	print "$key\t$val\n";
}
untie %file;
