##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;

sub
BoilersteuerungUtils_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.


sub Boilerstart (){

    my $stateInfrarot = ReadingsVal("infrarotheizung","relay_1","1");

    if($stateInfrarot eq "on"){
    my  $powerInfra = ReadingsVal("infrarotheizung","power_1","1");
    my  $powerSolar = ReadingsVal("shelly","power_0","0");

        my $diff = $powerSolar - $powerInfra;

        if($diff > 0){
            fhem("set BoilerA6.4 on");
        }
    } else {
        fhem("set BoilerA6.4 off");
    }

}



1;

1;
