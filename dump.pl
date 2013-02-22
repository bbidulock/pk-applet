#!/usr/bin/perl

my $fn = shift;

use GDBM_File;

tie %file, 'GDBM_File', $fn, &GDBM_READER, 0644 or die $!;
while (my ($key,$val) = each %file) {
	print "$key\t$val\n";
}
untie %file;
