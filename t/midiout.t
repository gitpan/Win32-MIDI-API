# -*- perl -*-
#	midiout.t : test Win32::MIDI::API::Out
#
#	Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
# test for MIDI::In have to be moved to midiin.t
use strict;
use Test;
BEGIN { plan tests => 2 };
use Win32::MIDI::API qw( /^(MIM_)/ );
use Data::Dumper;
my $i = 0;
ok(++$i); # If we made it this far, we're ok.

my $midi = new Win32::MIDI::API;
ok(++$i);

# subroutines
sub unpack3 {
    return (($_[0] >> 16) & 0xff, ($_[0] >> 8) & 0xff, $_[0] & 0xff);
}
sub checkSum {
    my $s = 0;
    $s += $_ foreach (@_);
    -$s & 0x7F;
}
#my $d = checkSum(unpack3(0x40007f));
#printf "0x%02x %d\n", $d, $d; exit;

# for debug
sub datadump {
    my ($m) = @_;
    my $l = length $m;
    foreach (unpack 'C*', $m) { printf "%02x ", $_; }; print ":length $l\n";
}

sub EXS { 0xf0; };		# Exclusive Status
sub EOX { 0xf7; };		# EOX: End Of Exclusive
sub UNM { 0x7e; };		# Universal Non-realtime Meesages
sub URM { 0x7f; };		# Universal Realtime Messages
sub BRD { 0x7f; };		# Broadcast Device ID

my %sysex;
$sysex{'Turn General MIDI System On'}
    = pack 'C*', EXS, UNM, 0x7f, 0x09, 0x01, EOX;
$sysex{'Turn General MIDI System Off'}
    = pack 'C*', EXS, UNM, 0x7f, 0x09, 0x02, EOX;
sub identifyRequest {
    my $dev = shift; $dev--;
    pack 'C*', EXS, UNM, ($dev & 0xff), 0x06, 0x01, EOX;
}
sub sysExMasterVolume {
    pack('C*', EXS, URM, BRD,
	 0x04,			# sub ID #1 : Device Control Message
	 0x01,			# sub ID #2 : Master Volume
	 $_[0] & 0x7f,		# volume (LSB)
	 ($_[0] >> 7) & 0x7f,	# volume (MSB)
	 EOX);
}

my %ID;
$ID{Roland} = 0x41;		# manufacture ID : Roland
# SC-55mkII
sub RequestData_RQ1 {
    my ($dev, $address, $size) = @_;
    $dev--;
    pack('C*', EXS, $ID{Roland},
	 $dev,
	 0x42,			# Model ID: for GS, 0x45 for SC-55, 155
	 0x11,			# command ID: RQ1
	 unpack3($address),	# address
	 unpack3($size),
	 checkSum(unpack3($address), unpack3($size)),
	 EOX);
}

sub DataTransfer_DT1 {
    my ($dev, $address, @data) = @_;
    $dev--;
    pack('C*', EXS, $ID{Roland},
	 $dev,
	 0x42,			# Model ID: for GS, 0x45 for SC-55, 155
	 0x12,			# command ID: DT1
	 unpack3($address),	# address
	 @data,
	 checkSum(unpack3($address), @data),
	 EOX);
}

sub RequestData_RQ1_4B {
    my ($dev, $address, $size) = @_;
    $dev--;
    pack('C6NNC2',
	 EXS, $ID{Roland},
	 $dev,
	 0x00, 0x3f,		# Model ID: for TD-6
	 0x11,			# command ID: RQ1
	 $address,		# address
	 $size,			# size
	 checkSum(unpack 'C*', pack('NN', $address, $size)),
	 EOX);
}

sub DataTransfer_DT1_4B {
    my ($dev, $address, @data) = @_;
    $dev--;
    pack('C6NC*',
	 EXS, $ID{Roland},
	 $dev,
	 0x00, 0x3f,		# Model ID: for TD-6
	 0x12,			# command ID: DT1
	 $address,		# address
	 @data,
	 checkSum(unpack('C*', pack('N', $address)), @data),
	 EOX);
}

my $devId = 17;			# default device ID
$sysex{'GS Reset'} = DataTransfer_DT1($devId, 0x40007f, 0x00);

sub sc55mkII_sysex {
    print "GS Reset\n";
    datadump($sysex{'GS Reset'});
    print "Set Master Volume\n";
    datadump(sysExMasterVolume(0xD20));
    print "example 2 (manual P.104): Request the level for a drum note.\n";
    datadump(RequestData_RQ1($devId, 0x41024b, 0x01));
    print "bulk dump: system parameter and all patch parameter\n";
    datadump(RequestData_RQ1($devId, 0x480000, 0x1D10));
    print "bulk dump: system parameter\n";
    datadump(RequestData_RQ1($devId, 0x480000, 0x10));
    print "bulk dump: common patch parameter\n";
    datadump(RequestData_RQ1($devId, 0x480010, 0x100));
    print "bulk dump: drum map1 all\n";
    datadump(RequestData_RQ1($devId, 0x490000, 0xe18));
}
#sc55mkII_sysex; exit 0;

sub td6_sysex {
    print "example 1 (on manual P.146)\n";
    datadump(DataTransfer_DT1_4B($devId, 0x01000326, 0x20));
    print "example 2 (on manual P.146)\n";
    datadump(RequestData_RQ1_4B($devId, 0x01000015, 0x1));
    print "bulk dump: all user song\n";
    datadump(RequestData_RQ1_4B($devId, 0x10000000, 0x0));
    print "bulk dump: Setup\n";
    datadump(RequestData_RQ1_4B($devId, 0x40000000, 0x0));
    print "bulk dump: drum kit 3\n";
    datadump(RequestData_RQ1_4B($devId, 0x41030000, 0x0));
    print "bulk dump: all drum kit\n";
    datadump(RequestData_RQ1_4B($devId, 0x417f0000, 0x0));
}
#td6_sysex; exit 0;

########################################################################
# output SysEX Message
sub Win32::MIDI::API::Out::sysex {
    my ($self, $m) = @_;
    # struct midiHdr
    my $midiHdr = pack ("PL4PL6",
			$m,	# lpData
			length $m, # dwBufferLength
			0, 0, 0, undef, 0, 0);
    # make pointer to struct midiHdr
    # cf. perlpacktut in Perl 5.8.0 or later (http://www.perldoc.com/)
    my $lpMidiOutHdr = unpack('L!', pack('P',$midiHdr));
    $self->PrepareHeader($lpMidiOutHdr)	  or die $self->GetErrorText();
    $self->LongMsg($lpMidiOutHdr)	  or die $self->GetErrorText();
    $self->UnprepareHeader($lpMidiOutHdr) or die $self->GetErrorText();
}

sub midi_out_test {
    print "new...";
    my $mo = new Win32::MIDI::API::Out(0)	or die $midi->OutGetErrorText();
    print "done\n";

    testShortMsg($mo);
    out_header_test($mo);

    #$mo->sysex($sysex{'Turn General MIDI System Off'});
    #$mo->sysex($sysex{'Turn General MIDI System On'});

    $mo->sysex($sysex{'GS Reset'});
    $mo->sysex(sysExMasterVolume(0xD20));

    # Close the MIDI device */
    $mo->Close;
}
midi_out_test; exit 0;

sub out_header_test {
    my $mo = shift;

    my $buf = "abcdef";
    my $bufsize = length $buf;
    my $ptr = unpack('L!', pack('P', $buf));
    printf "ptr: 0x%08x\n", $ptr;

    my $midihdr = pack ("PLLLLPLL",
			$buf,	# lpData
			length $buf, # dwBufferLength
			0,	# dwBytesRecorded
			0xDEAD,	# dwUser
			0,	# dwFlags
			undef,	# lpNext
			0,	# reserved
			0);	# dwOffset
    my $lpMidiOutHdr = unpack('L!', pack('P', $midihdr));
    printf "lpMidiOutHdr: 0x%08x\n", $lpMidiOutHdr;

    my @h = unpack("P${bufsize}LLLLpLL", $midihdr);
    print Dumper(@h);

#    my $hdr = unpack('P', pack('L!', $lpMidiOutHdr));
    my @d = unpack('LL4LL', $midihdr);
    my $lpData = $d[0];
#      printf("lpData:0x%x,0x%p,0x%x,$lpData\n",
#  	   $lpData,		# == $ptr (correct)
#  	   $lpData,		# What does %p show?
#  	   unpack('P1024', pack('L!', $lpData)));

    @h = unpack("P${bufsize}LLLLpLL", $midihdr);
    print Dumper(@h);

    $mo->PrepareHeader($lpMidiOutHdr) or die $mo->GetErrorText();

    $mo->UnprepareHeader($lpMidiOutHdr) or die $mo->GetErrorText();
}

sub testShortMsg {
    my $mo = shift;
    # Output the C note (ie, sound the note)
    $mo->ShortMsg(0x00403C90);
    # Output the E note
    $mo->ShortMsg(0x00404090);
    # Output the G note
    $mo->ShortMsg(0x00404390);
    sleep(1);
    # turn off those 3 notes
    $mo->ShortMsg(0x00003C90);
    $mo->ShortMsg(0x00004090);
    $mo->ShortMsg(0x00004390);
}
