# -*- perl -*-
#	midiin.t : test Win32::MIDI::API::In
#
#	Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
use strict;
use Test;
BEGIN { plan tests => 11 };
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
	 $_[0] & 0xff,		# volume (LSB)
	 ($_[0] >> 8) & 0xff,	# volume (MSB)
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

sub midi_in_test {
    print "MIDI::API::In\n";
    my $mi = new Win32::MIDI::API::In(0, \&midiincallback, 0x1234)
	or die $midi->InGetErrorText();
    ok(++$i);

    my $buf = "\0" x 1024;
    my $midihdr = pack ("PLLLLPLL",
			$buf,	# lpData
			length $buf, # dwBufferLength
			0,	# dwBytesRecorded
			0xBEEF,	# dwUser
			0,	# dwFlags
			undef,	# lpNext
			0,	# reserved
			0);	# dwOffset
    my $lpMidiInHdr = unpack('L!', pack('P', $midihdr));
#    printf "lpMidiInHdr: 0x%08x\n", $lpMidiInHdr;

    $mi->PrepareHeader($lpMidiInHdr)	or die $mi->GetErrorText(); ok(++$i);
    $mi->AddBuffer($lpMidiInHdr)	or die $mi->GetErrorText(); ok(++$i);
    $mi->Start				or die $mi->GetErrorText(); ok(++$i);

    my $mo = new Win32::MIDI::API::Out(0)	or die $midi->OutGetErrorText();
    ok(++$i);

    #sc55mkII
    #print "example 2 (manual P.104): Request the level for a drum note.\n";
    $mo->sysex(RequestData_RQ1($devId, 0x41024b, 0x01));

    print "Waiting...";
    sleep 2;
    print "done (sleep)\n";
    $mo->Close				or die $mo->GetErrorText(); ok(++$i);
    $mi->Reset				or die $mi->GetErrorText(); ok(++$i);
    $mi->UnprepareHeader($lpMidiInHdr)	or die $mi->GetErrorText(); ok(++$i);
    $mi->Close				or die $mi->GetErrorText(); ok(++$i);
}
midi_in_test; exit 0;

#package Win32::MIDI::API::In;
sub midiincallback {
    my ($self, $msg, $instance, $param1, $param2) = @_;
    printf "<<<0x%x,0x%x,0x%x,0x%x>>>\n", $msg, $instance, $param1, $param2;
    if ($msg == MIM_OPEN) {
	print "MIM_OPEN\n";
    } elsif ($msg == MIM_CLOSE) {
	print "MIM_CLOSE\n";
    } elsif ($msg == MIM_ERROR) {
	print "MIM_ERROR\n";
    } elsif ($msg == MIM_DATA) {
	print "MIM_DATA\n";
    } elsif ($msg == MIM_LONGDATA) {
	print "MIM_LONGDATA\n";
	my $midiHdr = unpack('P32', pack('L!', $param1));
	my @d = unpack('LL4LL2', $midiHdr);
	printf "lpData:%x,Buflen:%x,bytesrecorded:%d,dwUser:%x,dwFlags:%d\n",
	    @d[0..4];
	datadump(unpack("P$d[2]", $midiHdr));
    } elsif ($msg == MIM_LONGERROR) {
	print "MIM_LONGERROR\n";
    } else {
	print "unknown message type\n";
    }
}
