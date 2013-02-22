#!/usr/bin/perl

use DB_File;

tie %hash, 'DB_File', './tmp2.db', O_RDWR|O_CREAT, 0644, $DB_HASH or die $!;
open($fh,"<","./tmp.log");
while (<$fh>) {
	chomp;
	my ($key,$val) = split(/\t/,$_);
	$hash{$key} = $val;
}
close($fh);
untie %hash;

