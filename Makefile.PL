#	 $Id: Makefile.PL,v 1.1 2002-09-14 00:53:28-05 hiroo Exp $
#
#	 Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
#
#	 This program is free software; you can redistribute it and/or
#	 modify it under the same terms as Perl itself.

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::MIDI::API',
    'VERSION_FROM'	=> 'API.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'API.pm', # retrieve abstract from module
       AUTHOR     => 'Hiroo Hayashi <hiroo.hayashi@computer.org>') : ()),
    'LIBS'		=> ['-L/usr/lib/w32api -lwinmm'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
