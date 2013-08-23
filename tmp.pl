
my $pacdir = "/var/lib/pacman";
my $syncdir  = "$pacdir/sync";
my @dbs = map{chomp;$_} `find $syncdir -type f -name '*.db'`;
print join('',@dbs);
