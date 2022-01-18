##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;

sub
myUtils_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub
setSolarstromInWatt()
{
#Watt auslesen
my $power = ReadingsVal("shelly","power_0","0");
fhem("set solarstromInWatt $power");
}

sub
setCheckIntervallTime($)
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

    fhem("set checkWattIntervall modifyTimeSpec $fhemtime");
}

sub
setStromzaehlerShelly()
{
my $energy = ReadingsVal("shelly","energy_0","0");
my $stromzaheler = ReadingsVal("stromzaehlerShelly","state","0");
if($stromzaheler < $energy){
  fhem("set stromzaehlerShelly $energy");
}
}

1;
