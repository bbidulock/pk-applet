#!/usr/bin/perl

use strict;
use warnings;

use EV;

use AnyEvent;
use IO::Handle;
use Sys::Gamin qw(fd);

my $fm = Sys::Gamin->new($0);
my $io = IO::Handle->new();

my $fd = $fm->fc_fd();

my $w = AnyEvent->io(fh=>$fd,poll=>'r',cb=>sub{
	while ($fm->pending) {
		my $event = $fm->next_event;
		my $file = $event->filename;
		my $type = $event->type;
		print "EVENT($type) on file $file\n";
	}
});

$fm->monitor('/var/lib/pacman/local',undef,'dir');

EV::run;

