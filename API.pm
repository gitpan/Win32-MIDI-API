#!/usr/bin/perl
#
#	$Id: API.pm,v 1.8 2002-09-30 00:10:07-05 hiroo Exp $
#
#	Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

package Win32::MIDI::API;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
#use AutoLoader;

our $VERSION = '0.03';

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(
       CALLBACK_EVENT CALLBACK_FUNCTION CALLBACK_NULL CALLBACK_TASK
       CALLBACK_THREAD CALLBACK_TYPEMASK CALLBACK_WINDOW

       MEVT_COMMENT MEVT_EVENTPARM MEVT_EVENTTYPE MEVT_F_CALLBACK MEVT_F_LONG
       MEVT_F_SHORT MEVT_LONGMSG MEVT_NOP MEVT_SHORTMSG MEVT_TEMPO MEVT_VERSION

       MIDICAPS_CACHE MIDICAPS_LRVOLUME MIDICAPS_STREAM MIDICAPS_VOLUME

       MIDIMAPPER MIDIPATCHSIZE MIDIPROP_GET MIDIPROP_SET MIDIPROP_TEMPO
       MIDIPROP_TIMEDIV MIDISTRM_ERROR MIDI_CACHE_ALL MIDI_CACHE_BESTFIT
       MIDI_CACHE_QUERY MIDI_IO_STATUS MIDI_MAPPER MIDI_UNCACHE

       MIXERLINE_TARGETTYPE_MIDIIN MIXERLINE_TARGETTYPE_MIDIOUT
       MIXER_OBJECTF_HMIDIIN MIXER_OBJECTF_HMIDIOUT
       MIXER_OBJECTF_MIDIIN MIXER_OBJECTF_MIDIOUT

       MIDIERR_BADOPENMODE MIDIERR_BASE MIDIERR_DONT_CONTINUE
       MIDIERR_INVALIDSETUP MIDIERR_LASTERROR MIDIERR_NODEVICE MIDIERR_NOMAP
       MIDIERR_NOTREADY MIDIERR_STILLPLAYING MIDIERR_UNPREPARED

       MMSYSERR_ALLOCATED MMSYSERR_BADDB MMSYSERR_BADDEVICEID
       MMSYSERR_BADERRNUM MMSYSERR_BASE MMSYSERR_DELETEERROR MMSYSERR_ERROR
       MMSYSERR_HANDLEBUSY MMSYSERR_INVALFLAG MMSYSERR_INVALHANDLE
       MMSYSERR_INVALIDALIAS MMSYSERR_INVALPARAM MMSYSERR_KEYNOTFOUND
       MMSYSERR_LASTERROR MMSYSERR_NODRIVER MMSYSERR_NODRIVERCB
       MMSYSERR_NOERROR MMSYSERR_NOMEM MMSYSERR_NOTENABLED
       MMSYSERR_NOTSUPPORTED MMSYSERR_READERROR MMSYSERR_VALNOTFOUND
       MMSYSERR_WRITEERROR

       MM_MIM_CLOSE MM_MIM_DATA MM_MIM_ERROR MM_MIM_LONGDATA
       MM_MIM_LONGERROR MM_MIM_MOREDATA MM_MIM_OPEN

       MIM_CLOSE MIM_DATA MIM_ERROR MIM_LONGDATA
       MIM_LONGERROR MIM_MOREDATA MIM_OPEN

       MM_MOM_CLOSE MM_MOM_DONE MM_MOM_OPEN MM_MOM_POSITIONCB

       MOM_CLOSE MOM_DONE MOM_OPEN MOM_POSITIONCB

       TIME_CALLBACK_EVENT_PULSE TIME_CALLBACK_EVENT_SET
       TIME_CALLBACK_FUNCTION TIME_MIDI

       MOD_MIDIPORT MCIERR_SEQ_NOMIDIPRESENT MCI_SEQ_MIDI
      );

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "$& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	} else {
	    croak "Your vendor has not defined Win32::MIDI::API macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#	if ($] >= 5.00561) {
#	    *$AUTOLOAD = sub () { $val };
#	} else {
	    *$AUTOLOAD = sub { $val };
#	}
    }
    goto &$AUTOLOAD;
}

bootstrap Win32::MIDI::API $VERSION;

# Preloaded methods go here.

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub InGetNumDevs {
    my $self = shift;
    return midiInGetNumDevs();
}

sub OutGetNumDevs {
    my $self = shift;
    return midiOutGetNumDevs();
}

sub InGetDevCaps {
    my $self = shift;
    return midiInGetDevCaps(@_);
}

sub OutGetDevCaps {
    my $self = shift;
    return midiOutGetDevCaps(@_);
}

sub syserr {
    my $self = shift;
    return midisyserr();
}

sub InGetErrorText {
    my $self = shift;
    $self->Win32::MIDI::API::In::GetErrorText(@_);
}

sub OutGetErrorText {
    my $self = shift;
    $self->Win32::MIDI::API::Out::GetErrorText(@_);
}


package Win32::MIDI::API::In;

sub new {
    my $class = shift;
    my $self = Open(@_);
    bless $self, $class if defined $self;
    return $self;
}

# Commented out because this is invoked when a callback function finishes.
#  sub DESTROY {
#      my $self = shift;
#      $self->Close;
#  }

sub Connect {
    Win32::MIDI::API::midiConnect(@_);
}

sub Disconnect {
    Win32::MIDI::API::midiDisconnect(@_);
}


package Win32::MIDI::API::Out;

sub new {
    my $class = shift;
    my $self = Open(@_);
    bless $self, $class if defined $self;
    return $self;
}

# Commented out because this is invoked when a callback function finishes.
#  sub DESTROY {
#      my $self = shift;
#      $self->Close;
#  }

# for MIDI through device
sub Connect {
    Win32::MIDI::API::midiConnect(@_);
}

# for MIDI through device
sub Disconnect {
    Win32::MIDI::API::midiDisconnect(@_);
}


package Win32::MIDI::API::Stream;

sub new {
    my $class = shift;
    my $self = Open(@_);
    bless $self, $class if defined $self;
    return $self;
}

sub PrepareHeader {
    my $self = shift;
    $self->Win32::MIDI::API::Out::PrepareHeader(@_);
}

sub UnprepareHeader {
    my $self = shift;
    $self->Win32::MIDI::API::Out::UnprepareHeader(@_);
}

sub GetErrorText {
    my $self = shift;
    $self->Win32::MIDI::API::Out::GetErrorText(@_);
}

# Commented out because this is invoked when a callback function finishes.
#  sub DESTROY {
#      my $self = shift;
#      $self->Close;
#  }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

Win32::MIDI::API - Perl extension for MS Windows 32bit MIDI API

=head1 SYNOPSIS

  use Win32::MIDI::API qw( /^(MIM_)/ );
  $midi = new Win32::MIDI::API;

  # MIDI::Out::ShortMsg
  $mo = new Win32::MIDI::API::Out	   or die $midi->OutGetErrorText();
  $mo->ShortMsg(0x00403C90)			or die $mo->GetErrorText();
  sleep(1);
  $mo->ShortMsg(0x00003C90)			or die $mo->GetErrorText();
  $mo->Close					or die $mo->GetErrorText();

  # MIDI::Out::LongMsg
  $mo = new Win32::MIDI::API::Out	   or die $midi->OutGetErrorText();
  # sysEx: Set Master Volume
  $m = "\xf0\x7f\x7f\x04\x01\x7f\x7f\xf7";
  $midiHdr = pack ("PL4PL6",
  		   $m,	# lpData
  		   length $m, # dwBufferLength
  		   0, 0, 0, undef, 0, 0);
  $mo->PrepareHeader(unpack('L!', pack('P',$midiHdr)))
			 			or die $mo->GetErrorText();
  $mo->LongMsg($lpMidiOutHdr)			or die $mo->GetErrorText();
  $mo->UnprepareHeader($lpMidiOutHdr)		or die $mo->GetErrorText();
  $mo->Close					or die $mo->GetErrorText();

  # MIDI::Stream
  $ms = new Win32::MIDI::API::Stream()	   or die $midi->OutGetErrorText();
  $buf = pack('L*',
	      # System Exclusive (Set Master Volume Full)
	      0,  0, (&MEVT_LONGMSG << 24) | 8, 0x047F7FF0, 0xF77F7F01,
	      # Short Messages
	      0,  0, 0x007F3C90,
	      48, 0, 0x00003C90);
  $midihdr = pack("PLLLLPLL",
		  $buf,	# lpData
		  length $buf,	# dwBufferLength
		  length $buf,	# dwBytesRecorded
		  0,		# dwUser
		  0,		# dwFlags
		  undef,	# lpNext
		  0,		# reserved
		  0);		# dwOffset
  $lpMidiHdr = unpack('L!', pack('P', $midihdr));
  $ms->PrepareHeader($lpMidiHdr)		or die $ms->GetErrorText();
  $ms->Out($lpMidiHdr)				or die $ms->GetErrorText();
  $ms->Restart()				or die $ms->GetErrorText();
  sleep(1);
  $ms->UnprepareHeader($lpMidiHdr)		or die $ms->GetErrorText();
  $ms->Close()					or die $ms->GetErrorText();

  # MIDI::In
  $mi = new Win32::MIDI::API::In(0, \&midiincallback, 0x1234)
					    or die $midi->InGetErrorText();
  sub midiincallback {
    my ($self, $msg, $instance, $param1, $param2) = @_;
    if ($msg == MIM_OPEN) {
  	  print "MIM_OPEN\n";
  	  ...
    } elsif ($msg == MIM_LONGDATA) {
  	  print "MIM_LONGDATA\n";
  	  ...
    }
  }
  $buf = "\0" x 1024;
  $midihdr = pack ("PLLLLPLL",
		   $buf,	# lpData
		   length $buf, # dwBufferLength
		   0,		# dwBytesRecorded
		   0xBEEF,	# dwUser
		   0,		# dwFlags
		   undef,	# lpNext
		   0,		# reserved
		   0);		# dwOffset
  $lpMidiInHdr = unpack('L!', pack('P', $midihdr));
  $mi->PrepareHeader($lpMidiInHdr)		or die $mi->GetErrorText();
  $mi->AddBuffer($lpMidiInHdr)			or die $mi->GetErrorText();
  $mi->Start					or die $mi->GetErrorText();
  $mi->Reset					or die $mi->GetErrorText();
  $mi->UnprepareHeader($lpMidiInHdr)		or die $mi->GetErrorText();
  $mi->Close()					or die $ms->GetErrorText();

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

=head1 DESCRIPTION

=head2 Overview

Win32::MIDI::API is a wrapper for MS Windows 32bit MIDI API.  It supports
all MS Windoews 32bit MIDI API, MIDI output, input, and stream API.

This module is still under development.  Interface may be changed to
improve usability.

=head2 Querying MIDI Devices

=over 4

=item C<$midi = new Win32::MIDI::API;>

=item C<$midi->InGetNumDevs()>

=item C<$midi->OutGetNumDevs()>

=item C<$midi->InGetDevCapss(DeviceID)>

=item C<$midi->OutGetDevCapss([DeviceID = MIDI_MAPPER])>

=back

=head2 Playing MIDI

=head3 Opening and Closing MIDI Output Device

=over 4

=item C<$midiOut = new Win32::MIDI::API::Out([DeviceID = MIDI_MAPPER,
 					     [Callback = undef,
					     [CallbackInstance = undef,
					     [Flags = CALLBACK_NULL]]]]);>

=item C<$midiOut->GetID()>

=item C<$midiOut->Close()>

=back

=head3 Sending Individual MIDI Messages

=over 4

=item C<$midiOut->ShortMsg(Msg)>

=item C<$midiOut->PrepareHeader($lpMidiOutHdr)>

Preparing a header that has already been prepared has no effect, and
the function returns zero.

After the header has been prepared, do not modify the buffer.  To free
the buffer, use the midiInUnprepareHeader function.

Before using this function, you must set the lpData, dwBufferLength,
and dwFlags members of the MIDIHDR structure.

The dwFlags member must be set to zero.

A stream buffer cannot be larger than 64K.

=item C<$midiOut->UnprepareHeader($lpMidiOutHdr)>

=item C<$midiOut->LongMsg($lpMidiOutHdr)>

=back

=head3 Misc.

=over 4

=item C<$midiOut->GetErrorText([mmsyserr])>

=item C<$midiOut->Reset()>

=item C<$midiOut->Connect($midiOut1)>

=item C<$midiOut->Disconnect($midiOut1)>

=back

=head2 Recording MIDI Audio

=head3 Opening and Closing MIDI Output Device

=over 4

=item C<$midiIn = new Win32::MIDI::API::In(DeviceID,
 				 	   [Callback = undef,
				 	   [CallbackInstance = undef,
				 	   [Flags = CALLBACK_NULL]]]);>

=item C<$midiIn->GetID()>

=item C<$midiIn->Close()>

=back

=head3 Managing MIDI Recording

=over 4

=item C<$midiIn->PrepareHeader($lpMidiInHdr)>

Preparing a header that has already been prepared has no effect, and
the function returns zero.

After the header has been prepared, do not modify the buffer.  To free
the buffer, use the midiInUnprepareHeader function.

Before using this function, you must set the lpData, dwBufferLength,
and dwFlags members of the MIDIHDR structure.

The dwFlags member must be set to zero.

=item C<$midiIn->UnprepareHeader($lpMidiInHdr)>

=item C<$midiIn->AddBuffer($lpMidiInHdr)>

=item C<$midiIn->Reset()>

=item C<$midiIn->Start()>

=item C<$midiIn->Stop()>

=item C<$midiIn->GetErrorText([$mmsyserr])>

=item C<$midiIn->Connect($midiOut1)>

=item C<$midiIn->Disconnect($midiOut1)>

=back

=head2 Sending MIDI Messages with Stream Buffers

=over 4

=item C<$midiStream = new Win32::MIDI::API::Stream([DeviceID = MIDI_MAPPER,
						   [Callback = undef,
						   [CallbackInstance = undef,
						   [Flags = CALLBACK_NULL]]]]);>

=item C<$midiStream->Close()>

=item C<$midiStream->PrepareHeader($lpMidiInHdr)>

Preparing a header that has already been prepared has no effect, and
the function returns zero.

After the header has been prepared, do not modify the buffer.  To free
the buffer, use the midiInUnprepareHeader function.

Before using this function, you must set the lpData, dwBufferLength,
and dwFlags members of the MIDIHDR structure.

The dwFlags member must be set to zero.

A stream buffer cannot be larger than 64K.

=item C<$midiStream->UnprepareHeader($lpMidiInHdr)>

=item C<$midiStream->Out($midiOutHdr)>

=item C<$midiStream->Restart()>

=item C<$midiStream->Pause()>

=item C<$midiStream->Stop()>

=item C<$midiStream->GetErrorText([$mmsyserr])>

=item C<$midiStream->Position($lpmmtime)>

=item C<$midiStream->Property($lppropdata, $dwProperty)>

=back

=head1 EXPORT

None by default.  The following constant values can be exported.

       CALLBACK_EVENT CALLBACK_FUNCTION CALLBACK_NULL CALLBACK_TASK
       CALLBACK_THREAD CALLBACK_TYPEMASK CALLBACK_WINDOW

       MEVT_COMMENT MEVT_EVENTPARM MEVT_EVENTTYPE MEVT_F_CALLBACK MEVT_F_LONG
       MEVT_F_SHORT MEVT_LONGMSG MEVT_NOP MEVT_SHORTMSG MEVT_TEMPO MEVT_VERSION

       MIDICAPS_CACHE MIDICAPS_LRVOLUME MIDICAPS_STREAM MIDICAPS_VOLUME

       MIDIMAPPER MIDIPATCHSIZE MIDIPROP_GET MIDIPROP_SET MIDIPROP_TEMPO
       MIDIPROP_TIMEDIV MIDISTRM_ERROR MIDI_CACHE_ALL MIDI_CACHE_BESTFIT
       MIDI_CACHE_QUERY MIDI_IO_STATUS MIDI_MAPPER MIDI_UNCACHE

       MIXERLINE_TARGETTYPE_MIDIIN MIXERLINE_TARGETTYPE_MIDIOUT
       MIXER_OBJECTF_HMIDIIN MIXER_OBJECTF_HMIDIOUT
       MIXER_OBJECTF_MIDIIN MIXER_OBJECTF_MIDIOUT

       MIDIERR_BADOPENMODE MIDIERR_BASE MIDIERR_DONT_CONTINUE
       MIDIERR_INVALIDSETUP MIDIERR_LASTERROR MIDIERR_NODEVICE MIDIERR_NOMAP
       MIDIERR_NOTREADY MIDIERR_STILLPLAYING MIDIERR_UNPREPARED

       MMSYSERR_ALLOCATED MMSYSERR_BADDB MMSYSERR_BADDEVICEID
       MMSYSERR_BADERRNUM MMSYSERR_BASE MMSYSERR_DELETEERROR MMSYSERR_ERROR
       MMSYSERR_HANDLEBUSY MMSYSERR_INVALFLAG MMSYSERR_INVALHANDLE
       MMSYSERR_INVALIDALIAS MMSYSERR_INVALPARAM MMSYSERR_KEYNOTFOUND
       MMSYSERR_LASTERROR MMSYSERR_NODRIVER MMSYSERR_NODRIVERCB
       MMSYSERR_NOERROR MMSYSERR_NOMEM MMSYSERR_NOTENABLED
       MMSYSERR_NOTSUPPORTED MMSYSERR_READERROR MMSYSERR_VALNOTFOUND
       MMSYSERR_WRITEERROR

       MM_MIM_CLOSE MM_MIM_DATA MM_MIM_ERROR MM_MIM_LONGDATA
       MM_MIM_LONGERROR MM_MIM_MOREDATA MM_MIM_OPEN

       MIM_CLOSE MIM_DATA MIM_ERROR MIM_LONGDATA
       MIM_LONGERROR MIM_MOREDATA MIM_OPEN

       MM_MOM_CLOSE MM_MOM_DONE MM_MOM_OPEN MM_MOM_POSITIONCB

       MOM_CLOSE MOM_DONE MOM_OPEN MOM_POSITIONCB

       TIME_CALLBACK_EVENT_PULSE TIME_CALLBACK_EVENT_SET
       TIME_CALLBACK_FUNCTION TIME_MIDI

       MOD_MIDIPORT MCIERR_SEQ_NOMIDIPRESENT MCI_SEQ_MIDI

=head1 AUTHOR

Hiroo Hayashi, E<lt>hiroo.hayashi@computer.orgE<gt>

=head1 SEE ALSO

=over 4

=item MICROSOFT Developer Network

	http://msdn.microsoft.com/library/

=back

=head1 TODO

port and test on Active Perl.

=head1 BUGS

If you find bugs, report to the author.  Thank you.

=cut
