#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION=>'0.01',
  NAME=>q(sd-applet),
  EXE_FILES=>[qw(sd-applet)],
);
