##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;

sub
ConversionsUtils_Initialize ($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub convert_to_seconds ($){
	# Konvertiert das Zeitformat von FHEM in Sekunden seit JAN 01 1970
        use Time::Local;
	
	my ($Zeitstempel) = @_;
	
	my @Zeitarray = split(/[-: ]/,$Zeitstempel);
	
	my $second = $Zeitarray[5];
	my $minute = $Zeitarray[4];
	my $hour = $Zeitarray[3];
	my $day = $Zeitarray[2];
	my $month = $Zeitarray[1];
	my $year = $Zeitarray[0];
	
	my $returntime = timelocal($second,$minute,$hour,$day,$month-1,$year);

	return $returntime;
}

sub convert_to_fhemtime ($){
    # Konvertiert von Sekunden seit JAN 01 1970 in das Format von FHEM
	
	#use 5.010;
	use Time::Piece;

	my ($Zeitstempel) = @_;

	my $returntime = localtime($Zeitstempel)->strftime('%F %T');
	
	return $returntime;
}

1;
