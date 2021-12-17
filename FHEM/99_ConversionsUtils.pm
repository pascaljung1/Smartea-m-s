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
	
	my @Zeitarray = split(/[-: ]/,$Zeitstempel,6);

	
	my $returntime = timelocal($Zeitarray[5],$Zeitarray[4],$Zeitarray[3],$Zeitarray[2],--$Zeitarray[1],$Zeitarray[0]);

Log 1, $returntime;

	return $returntime;
}

sub convert_to_fhemtime ($){
    # Konvertiert von Sekunden seit JAN 01 1970 in das Format von FHEM
	
	#use 5.010;
	use Time::Piece;

	my ($Zeitstempel) = @_;

	my $returntimez = localtime($Zeitstempel)->strftime('%F %T');
	
	return $returntimez;
}

sub is_time_passed ($$){
	# Zeitstempel der Überprüft wird
	my ($Zeitstempel,$Zeitspanne) = @_;
	my $time = time();
	
	my $differenz = $time - $Zeitstempel;
	
	if ($differenz < $Zeitspanne) {
		return "false";
	}	
	
	return "true";
}

1;
