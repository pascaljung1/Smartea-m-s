###############################################################################
#
# Developed with Kate
#
#  (c) 2018-2021 Copyright: Marko Oldenburg (fhemdevelopment@cooltux.net)
#  All rights reserved
#
#   Special thanks goes to:
#       - Bernd (Cluni) this module is based on the logic of his script "Rollladensteuerung für HM/ROLLO inkl. Abschattung und Komfortfunktionen in Perl" (https://forum.fhem.de/index.php/topic,73964.0.html)
#       - Beta-User for many tests, many suggestions and good discussions
#       - pc1246 write english commandref
#       - FunkOdyssey commandref style
#       - sledge fix many typo in commandref
#       - many User that use with modul and report bugs
#       - Christoph (christoph.kaiser.in) Patch that expand RegEx for Window Events
#       - Julian (Loredo) expand Residents Events for new Residents functions
#       - Christoph (Christoph Morrison) for fix Commandref, many suggestions and good discussions
#
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License,or
#  any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#
# $Id: Roommate.pm 25056 2021-10-09 05:20:08Z CoolTux $
#
###############################################################################

## Klasse ASC_Roommate ##
package FHEM::Automation::ShuttersControl::Roommate;

use strict;
use warnings;
use utf8;

use GPUtils qw(GP_Import);

## Import der FHEM Funktionen
BEGIN {
    GP_Import(
        qw(
          ReadingsVal)
    );
}

sub _getRoommateStatus {
    my $self = shift;

    my $roommate = $self->{roommate};

    return ReadingsVal( $roommate,
        $FHEM::Automation::ShuttersControl::shutters->getRoommatesReading,
        'none' );
}

sub _getRoommateLastStatus {
    my $self = shift;

    my $roommate = $self->{roommate};
    my $default  = $self->{defaultarg};

    $default = 'none' if ( !defined($default) );
    return ReadingsVal( $roommate, 'lastState', $default );
}




1;
