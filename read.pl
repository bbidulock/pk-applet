#!/usr/bin/perl

use GDBM_File;

tie %file, 'GDBM_File', './tmp.db', &GDBM_WRCREAT, 0644 or die $!;
open($fh,"<","./tmp.log");
while (<$fh>) {
	chomp;
	my ($key,$val) = split(/\t/,$_);
	$file{$key} = $val;
}
close($fh);
untie %file;
