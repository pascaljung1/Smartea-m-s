package main;

use strict;
use warnings;
use Switch;
use Time::Compare;

sub SteckdosenUtils_Initialize($$)
{
  my ($hash) = @_;
}

sub funksteckdosenModusSwitch
{
  my ($betriebsModus)=@_;

  switch ($betriebsModus) {
    case "a"  {
      fhem("defmod funk_kette_an_aus DOIF ([17:00]) (set funk_kette on-till-overnight 07:00)");
      fhem("attr funk_kette_an_aus room A4");
      fhem("attr funk_kette_an_aus userattr Betriebsmodus");
      fhem("attr funk_kette_an_aus userReadings einschaltzeit { funksteckdosenEinZeit('$betriebsModus') }, ausschaltzeit { funksteckdosenAusZeit('$betriebsModus') }");
      fhem("attr funk_kette_an_aus Betriebsmodus a");
      fhem("set funk_kette_an_aus initialize");
    }
    case "b"  {    
      fhem("defmod funk_kette_an_aus DOIF ([{sunset(0)}]) (set funk_kette on-till-overnight *{sunrise(0)})");
      fhem("attr funk_kette_an_aus room A4");
      fhem("attr funk_kette_an_aus userattr Betriebsmodus");
      fhem("attr funk_kette_an_aus userReadings einschaltzeit { funksteckdosenEinZeit('$betriebsModus') }, ausschaltzeit { funksteckdosenAusZeit('$betriebsModus') }");
      fhem("attr funk_kette_an_aus Betriebsmodus b");
      fhem("set funk_kette_an_aus initialize");
    }
    case "c"  {
      fhem("defmod funk_kette_an_aus DOIF ([07:30:00|AT] and ([{sunrise_abs(0)}] > [07:30:00])) (set funk_kette off) DOELSEIF ([{sunset(0)}]) (set wlan_kette on-till-overnight *{sunrise(0)})");
      fhem("attr funk_kette_an_aus room A4");
      fhem("attr funk_kette_an_aus userattr Betriebsmodus");
      fhem("attr funk_kette_an_aus Betriebsmodus c");
      fhem("attr funk_kette_an_aus userReadings einschaltzeit { funksteckdosenEinZeit('$betriebsModus') }, ausschaltzeit { funksteckdosenAusZeit('$betriebsModus') }");
      fhem("set funk_kette_an_aus initialize");
    }
    case "d"  {
      fhem("defmod funk_kette_an_aus DOIF ([17:00-07:00|AT] and [\"^iPhone.*:present\"]) (set funk_kette on) DOELSEIF ([{sunset(0)} | WE]) (set funk_kette on-till-overnight *{sunrise(0)}) DOELSE (set funk_kette off)");
      fhem("attr funk_kette_an_aus room A4");
      fhem("attr funk_kette_an_aus userattr Betriebsmodus");
      fhem("attr funk_kette_an_aus userReadings einschaltzeit { funksteckdosenEinZeit('$betriebsModus') }, ausschaltzeit { funksteckdosenAusZeit('$betriebsModus') }");
      fhem("attr funk_kette_an_aus Betriebsmodus d");
      fhem("set funk_kette_an_aus initialize");
    } 
  }
}

sub wlansteckdosenModusSwitch
{
  my ($betriebsModus)=@_;

  switch ($betriebsModus) {
    case "a"  {
      fhem("defmod wlan_kette_an_aus DOIF ([18:00]) (set wlan_kette on-till-overnight 08:00)");
      fhem("attr wlan_kette_an_aus room A4");
      fhem("attr wlan_kette_an_aus userattr Betriebsmodus");
      fhem("attr wlan_kette_an_aus userReadings einschaltzeit { wlansteckdosenEinZeit('$betriebsModus') }, ausschaltzeit { wlansteckdosenAusZeit('$betriebsModus') }");
      fhem("attr wlan_kette_an_aus Betriebsmodus a");
      fhem("set wlan_kette_an_aus initialize");
    }
    case "b"  {    
      fhem("defmod wlan_kette_an_aus DOIF ([{sunset(0)}]) (set wlan_kette on-till-overnight *{sunrise(0)})");
      fhem("attr wlan_kette_an_aus room A4");
      fhem("attr wlan_kette_an_aus userattr Betriebsmodus");
      fhem("attr wlan_kette_an_aus userReadings einschaltzeit { wlansteckdosenEinZeit('$betriebsModus') }, ausschaltzeit { wlansteckdosenAusZeit('$betriebsModus') }");
      fhem("attr wlan_kette_an_aus Betriebsmodus b");
      fhem("set wlan_kette_an_aus initialize");
    }
    case "c"  {
      fhem("defmod wlan_kette_an_aus DOIF ([07:30:00|AT] and ([{sunrise_abs(0)}] > [07:30:00])) (set wlan_kette off) DOELSEIF ([{sunset(0)}]) (set wlan_kette on-till-overnight *{sunrise(0)})");
      fhem("attr wlan_kette_an_aus room A4");
      fhem("attr wlan_kette_an_aus userattr Betriebsmodus");
      fhem("attr wlan_kette_an_aus userReadings einschaltzeit { wlansteckdosenEinZeit('$betriebsModus') }, ausschaltzeit { wlansteckdosenAusZeit('$betriebsModus') }");
      fhem("attr wlan_kette_an_aus Betriebsmodus c");
      fhem("set wlan_kette_an_aus initialize");
    }
    case "d"  {
      fhem("defmod wlan_kette_an_aus DOIF ([17:00-07:00|AT] and [\"^iPhone.*:present\"]) (set wlan_kette on) DOELSEIF ([{sunset(0)} | WE]) (set wlan_kette on-till-overnight *{sunrise(0)}) DOELSE (set wlan_kette off)");
      fhem("attr wlan_kette_an_aus room A4");
      fhem("attr wlan_kette_an_aus userattr Betriebsmodus");
      fhem("attr wlan_kette_an_aus userReadings einschaltzeit { wlansteckdosenEinZeit('$betriebsModus') }, ausschaltzeit { wlansteckdosenAusZeit('$betriebsModus') }");
      fhem("attr wlan_kette_an_aus Betriebsmodus d");
      fhem("set wlan_kette_an_aus initialize");
    }
  }
}

sub funksteckdosenEinZeit
{
  my ($betriebsModus)=@_;

  switch ($betriebsModus) {
    case "a" {
      my $einzeit = "17:00";
      return ($einzeit);
    }
    case "b"  {    
      return sunset_abs(0);
    }
    case "c"  {
      return sunset_abs(0); 
    }
    case "d"  {
      my $presenceIphone1 = ReadingsVal("iPhone1", "presence", "absent");
      my $presenceIphone2 = ReadingsVal("iPhone2", "presence", "absent");
      my $presenceIphone3 = ReadingsVal("iPhone3", "presence", "absent");
      my $presenceIphone4 = ReadingsVal("iPhone4", "presence", "absent");
      my $anypresence = (($presenceIphone1 eq "present") or ($presenceIphone2 eq "present") or ($presenceIphone3 eq "present") or ($presenceIphone4 eq "present"));
      # Am Wochenende erfolgt die Einschaltung zum Sonnenuntergang
      my $wday = (localtime)[6];

      if ($wday == 6 || $wday == 0) {
        my $einzeit = sunset_abs(0);
        return ($einzeit);
      } elsif ( (not($wday == 6 or $wday == 0)) and $anypresence) {
        my $einzeit = "17:00";
        return ($einzeit);
      } else {
        my $einzeit = "Keine Einschaltung geplant";
        return ($einzeit);
      }
    }
  }
}

sub funksteckdosenAusZeit
{
  my ($betriebsModus)=@_;

  switch ($betriebsModus) {
    case "a" {
      my $auszeit = "7:00";
      return ($auszeit);
    }
    case "b"  {    
      return sunrise_abs(0);
    }
    case "c"  {
      my $auszeit;
      my $wday = (localtime)[6];

      my $sunriseTime = Time::Compare->new(sunrise_abs(0));
      my $testTime = Time::Compare->new('07:30:00');
      
      if (($wday >0) and ($wday <6) and ($sunriseTime > $testTime)) { # sunrise_abs(0) > "07:30:00"
        $auszeit = "07:30:00";
        return $auszeit;
      } else {
        $auszeit = sunrise_abs(0);
        return $auszeit;
      }
    }
    case "d"  {
      my $presenceIphone1 = ReadingsVal("iPhone1", "presence", "absent");
      my $presenceIphone2 = ReadingsVal("iPhone2", "presence", "absent");
      my $presenceIphone3 = ReadingsVal("iPhone3", "presence", "absent");
      my $presenceIphone4 = ReadingsVal("iPhone4", "presence", "absent");
      my $anypresence = (($presenceIphone1 eq "present") or ($presenceIphone2 eq "present") or ($presenceIphone3 eq "present") or ($presenceIphone4 eq "present"));
      # Am Wochenende erfolgt die Einschaltung zum Sonnenuntergang
      my $wday = (localtime)[6];

      if ($wday == 6 || $wday == 0) {
        my $auszeit = sunset_abs(0);
        return ($auszeit);
      } elsif ( (not($wday == 6 or $wday == 0)) and $anypresence) {
        my $auszeit = "17:00";
        return ($auszeit);
      } else {
        my $auszeit = "Keine Einschaltung geplant";
        return ($auszeit);
      }
    }
  }
}

sub wlansteckdosenEinZeit
{
  my ($betriebsModus)=@_;

  switch ($betriebsModus) {
    case "a" {
      my $einzeit = "18:00";
      return ($einzeit);
    }
    case "b"  {    
      return sunset_abs(0);
    }
    case "c"  {
      return sunset_abs(0); 
    }
    case "d"  {
      my $presenceIphone1 = ReadingsVal("iPhone1", "presence", "absent");
      my $presenceIphone2 = ReadingsVal("iPhone2", "presence", "absent");
      my $presenceIphone3 = ReadingsVal("iPhone3", "presence", "absent");
      my $presenceIphone4 = ReadingsVal("iPhone4", "presence", "absent");
      my $anypresence = (($presenceIphone1 eq "present") or ($presenceIphone2 eq "present") or ($presenceIphone3 eq "present") or ($presenceIphone4 eq "present"));
      # Am Wochenende erfolgt die Einschaltung zum Sonnenuntergang
      my $wday = (localtime)[6];

      if ($wday == 6 || $wday == 0) {
        my $einzeit = sunset_abs(0);
        return ($einzeit);
      } elsif ( (not($wday == 6 or $wday == 0)) and $anypresence) {
        my $einzeit = "17:00";
        return ($einzeit);
      } else {
        my $einzeit = "Keine Einschaltung geplant";
        return ($einzeit);
      }
    }
  }
}

sub wlansteckdosenAusZeit
{
  my ($betriebsModus)=@_;

  switch ($betriebsModus) {
    case "a" {
      my $test = "8:00";
      return ($test);
    }
    case "b"  {    
      return sunrise_abs(0);
    }
    case "c"  {
      my $auszeit;
      my $wday = (localtime)[6];
      
      my $sunriseTime = Time::Compare->new(sunrise_abs(0));
      my $testTime = Time::Compare->new('07:30:00');
      
      if (($wday >0) and ($wday <6) and ($sunriseTime > $testTime)) {  
        $auszeit = "07:30:00";
        return $auszeit;
      } else {
        $auszeit = sunrise_abs(0);
        return $auszeit;
      } 
    }
    case "d"  {
      my $presenceIphone1 = ReadingsVal("iPhone1", "presence", "absent");
      my $presenceIphone2 = ReadingsVal("iPhone2", "presence", "absent");
      my $presenceIphone3 = ReadingsVal("iPhone3", "presence", "absent");
      my $presenceIphone4 = ReadingsVal("iPhone4", "presence", "absent");
      my $anypresence = (($presenceIphone1 eq "present") or ($presenceIphone2 eq "present") or ($presenceIphone3 eq "present") or ($presenceIphone4 eq "present"));
      # Am Wochenende erfolgt die Einschaltung zum Sonnenuntergang
      my $wday = (localtime)[6];

      if ($wday == 6 || $wday == 0) {
        my $auszeit = sunset_abs(0);
        return ($auszeit);
      } elsif ( (not($wday == 6 or $wday == 0)) and $anypresence) {
        my $auszeit = "17:00";
        return ($auszeit);
      } else {
        my $auszeit = "Keine Einschaltung geplant";
        return ($auszeit);
      }
    }
  }
}

1;
