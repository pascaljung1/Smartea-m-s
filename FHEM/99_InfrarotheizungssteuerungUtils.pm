##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $

package main;

use strict;
use warnings;

sub
InfrarotheizungssteuerungUtils_Initialize ($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub Heizungsstart ($$){
	
    my ($Balkonkraftwerk, $Infrarotheizung) = @_;
	
	#kraftwerk
	my $power = ReadingsVal("$Balkonkraftwerk","power_0","0");
	#Schwellenwerte
	my $schwellenwert = ReadingsVal("schwelle","state","0");
	#Zeiten in Sec
	my $Pausenzeit = ReadingsVal("pausenzeit","state","0");
	my $Arbeitszeit = ReadingsVal("arbeitszeit","state","0");
        #aktuelle Zeite
	my $zeitstempel = convert_to_fhemtime(time());

	#heizung
	my $status_infrarot = ReadingsVal("$Infrarotheizung","relay_1","1");
	my $pause_flag = $attr{"$Infrarotheizung"}{'userattr'};
	my $last_changed = convert_to_seconds (ReadingsTimestamp("$Infrarotheizung","relay_1","1"));

    #wenn ausgeschalten
    if ($status_infrarot eq "off" && $power >= $schwellenwert) {	
		
		my $pause_flag_sec = convert_to_seconds ($pause_flag);
		my $no_Cooldown = is_time_passed ($pause_flag_sec,$Pausenzeit);
		
		#Wenn nicht im 15 Minuten Cooldown-Intervall
		if($no_Cooldown eq "true") {
			fhem("set infrarotheizung on");
			fhem("att infrarotheizung userattr $zeitstempel");
		}
	}
	#wenn eingeschalten
	else {
		
		my $overheated = is_time_passed ($last_changed,$Arbeitszeit);
		#Wenn länger als definierte Arbeitszeit an
		if ($overheated eq "true"){
			fhem("set infrarotheizung off");
			fhem("att infrarotheizung userattr $zeitstempel");
		}
		else {
			if ( $power <= $schwellenwert){
				fhem("set infrarotheizung off");
			}
		}
	}

}
sub
setintervaltime($)
{
  my ($time) = @_;

    my $min = $time%60;
    $time = $time-$min;
    my $hour = $time/60;

    if ($hour <= 9){
        $hour = "0".$hour;
        }
    if ($min <= 9){
        $min= "0".$min;
        }
    
    my $fhemtime = $hour.":".$min;

    fhem("set check modifyTimeSpec $fhemtime");
    fhem("set checkinterval $fhemtime");
}



1;
