# -*- perl -*-
#	midi.t : test Win32::MIDI::API
#
#	Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

use strict;
use Test;
use Data::Dumper;
BEGIN { plan tests => 7 };
use Win32::MIDI::API qw( /^(CALLBACK_|TIME_|MIDIERR_)/ );
my $i = 0;
ok(++$i); # If we made it this far, we're ok.

# test new
my $midi = new Win32::MIDI::API;
ok(++$i);

# MIDI In Devs
my $InNumDevs  = $midi->InGetNumDevs();
ok(++$i);
for (0..$InNumDevs-1) {
    my $c = $midi->InGetDevCaps($_)
	or print $midi->InGetErrorText(), "\n";
    print "MIDI In Dev: $_\n";
    print Dumper(\$c);
}
ok(++$i);

# MIDI Out Devs
my $OutNumDevs = $midi->OutGetNumDevs();
ok(++$i);
for (-1..$OutNumDevs-1) {
    my $c = $midi->OutGetDevCaps($_)
	or print $midi->OutGetErrorText(), "\n";
    print "MIDI Out Dev: $_\n";
    print Dumper(\$c);
}
ok(++$i);

#
print (CALLBACK_EVENT, "\n");
print TIME_CALLBACK_EVENT_PULSE, "\n";
print MIDIERR_NODEVICE, "\n";
ok(++$i);

exit;
