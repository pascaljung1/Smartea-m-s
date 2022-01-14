##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $

package main;

use strict;
use warnings;

sub
optimiertesHeizenUtils_Initialize ($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub LuftTempSteuerung (){
	
	#sensorTemp
	my $temp = ReadingsVal("sensorHobbyraum","temperatur","0");
	#sensorLuft
	my $luft = ReadingsVal("sensorHobbyraum","luftfeuchtigkeit","0");
	#Schwellwerte
	my $tempMax = ReadingsVal("tempMax","state","0");
	my $tempMin = ReadingsVal("tempMin","state","0");
	my $luftMax = ReadingsVal("luftMax","state","0");
	my $luftMin = ReadingsVal("luftMin","state","0");

	#heizung einschalten
	if($temp < $tempMin || $luft >$luftMax){
			fhem("set infrarotheizung on");
		}
	#heizung ausschalten
	if($temp > $tempMax && $luft < $luftMin){
			fhem("set infrarotheizung off");
		}
}

sub OnOffOptimiertesHeizen () {
	
	my $status = ReadingsVal("optimiertesHeizen","state","0");
	
	if($status eq "inactive"){
			fhem("set triggerLuftMax inactive");
			fhem("set triggerLuftMin inactive");
			fhem("set triggerTempMax inactive");
			fhem("set triggerTempMin inactive");
		}else{
			fhem("set triggerLuftMax active");
			fhem("set triggerLuftMin active");
			fhem("set triggerTempMax active");
			fhem("set triggerTempMin active");
			fhem("set schaltercheck inactive");
		}
}


1;
