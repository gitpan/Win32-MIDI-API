# -*- perl -*-
#	midistream.t : test MIDI::Stream
#
#	Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

use strict;
use Test;
BEGIN { plan tests => 8 };
use Win32::MIDI::API qw( /^(MEVT_)/ );
#use Data::Dumper;
my $i = 0;
ok(++$i); # If we made it this far, we're ok.

my $midi = new Win32::MIDI::API;
ok(++$i);

my $ms = new Win32::MIDI::API::Stream()	or die $midi->OutGetErrorText();
ok(++$i);

# borrowed from Stream.c
my $buf = pack('L*',
	       # System Exclusive (set master volume full)
	       0,  0, (&MEVT_LONGMSG << 24) | 8, 0x047F7FF0, 0xF77F7F01,
	       # set tempo (0x50000 microsecond per quarter note)
	       0,  0, (&MEVT_TEMPO<<24) | 0x00050000,
	       # short messages
	       0,  0, 0x007F3C90,
	       48, 0, 0x00003C90,
	       0,  0, 0x007F3C90,
	       48, 0, 0x00003C90,

	       0,  0, 0x007F4390,
	       48, 0, 0x00004390,
	       0,  0, 0x007F4390,
	       48, 0, 0x00004390,

	       0,  0, 0x007F4590,
	       48, 0, 0x00004590,
	       0,  0, 0x007F4590,
	       48, 0, 0x00004590,

	       0,  0, 0x007F4390,
	       86, 0, 0x00004390,

	       10, 0, 0x007F4190,
	       48, 0, 0x00004190,
	       0,  0, 0x007F4190,
	       48, 0, 0x00004190,

	       0,  0, 0x007F4090,
	       48, 0, 0x00004090,
	       0,  0, 0x007F4090,
	       48, 0, 0x00004090,

	       0,  0, 0x007F3E90,
	       48, 0, 0x00003E90,
	       0,  0, 0x007F3E90,
	       48, 0, 0x00003E90,

	       0,  0, 0x007F3C90,
	       96, 0, 0x00003C90);
my $midihdr = pack ("PLLLLPLL",
		    $buf,	# lpData
		    length $buf, # dwBufferLength
		    length $buf, # dwBytesRecorded
		    0,		# dwUser
		    0,		# dwFlags
		    undef,	# lpNext
		    0,		# reserved
		    0);		# dwOffset
my $lpMidiHdr = unpack('L!', pack('P', $midihdr));

$ms->PrepareHeader($lpMidiHdr)		or die $ms->GetErrorText(); ok(++$i);
$ms->Out($lpMidiHdr)			or die $ms->GetErrorText(); ok(++$i);
$ms->Restart()				or die $ms->GetErrorText(); ok(++$i);
sleep(12);
$ms->UnprepareHeader($lpMidiHdr)	or die $ms->GetErrorText(); ok(++$i);
$ms->Close()				or die $ms->GetErrorText(); ok(++$i);

exit;
