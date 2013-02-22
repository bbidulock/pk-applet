#!/usr/bin/perl

use Gtk2;
use Gtk2::Notify -init, "test";
use Gtk2::TrayIcon;
Gtk2->init;

#my $icon = Gtk2::TrayIcon->new("test");
#my $label = Gtk2::Label->new("test");
#$icon->add($label);
#$icon->show_all;

my $stat = Gtk2::StatusIcon->new_from_stock("gtk-connect");
$stat->set_tooltip_text("This is a tooltip.");
$stat->set_visible(1);
#$stat->set_blinking(1);

my $notify = Gtk2::Notify->new_with_status_icon( "Hello", "Hello world!","gtk-connect",$stat);
$notify->attach_to_status_icon($stat);
$notify->show;

#my $msgid = $icon->send_message(10,"Hello world!");

Gtk2->main;
