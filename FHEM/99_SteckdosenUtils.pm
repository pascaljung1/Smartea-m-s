package main;

use strict;
use warnings;
use Switch;

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
      fhem("attr funk_kette_an_aus userattr Betriebsmodus Einschaltzeit Ausschaltzeit");
      fhem("attr funk_kette_an_aus Betriebsmodus a");
      fhem("attr funk_kette_an_aus Einschaltzeit 17:00");
      fhem("attr funk_kette_an_aus Ausschaltzeit 7:00");
    }
    case "b"  {    
      fhem("defmod funk_kette_an_aus DOIF ([{sunset(0)}]) (set funk_kette on-till-overnight *{sunrise(0)})");
      fhem("attr funk_kette_an_aus room A4");
      fhem("attr funk_kette_an_aus userattr Betriebsmodus Einschaltzeit Ausschaltzeit");
      fhem("attr funk_kette_an_aus Betriebsmodus b");
my $einzeit = sunset(0);
my $auszeit = sunrise_abs(0);
      fhem("attr funk_kette_an_aus Einschaltzeit $einzeit");
      fhem("attr funk_kette_an_aus Ausschaltzeit $auszeit");
    }
    case "c"  {
        fhem("defmod funk_kette_an_aus DOIF ([07:30:00|AT] and ([{sunrise_abs(0)}] > [07:30:00])) (set funk_kette off) DOELSEIF ([{sunset(0)}]) (set wlan_kette on-till-overnight *{sunrise(0)})");
        fhem("attr funk_kette_an_aus room A4");
        my $auszeit = sunrise_abs(0);
        my $einzeit = sunset_abs(0);
        fhem("attr funk_kette_an_aus room A4");
        fhem("attr funk_kette_an_aus userattr Betriebsmodus Einschaltzeit Ausschaltzeit");
        fhem("attr funk_kette_an_aus Betriebsmodus c");
        fhem("attr funk_kette_an_aus Einschaltzeit $einzeit");
        fhem("attr funk_kette_an_aus Ausschaltzeit $auszeit");
    }
    case "d"  {
      fhem("defmod funk_kette_an_aus DOIF ([17:00-07:00|AT] and [\"^iPhone.*:present\"]) (set funk_kette on) DOELSEIF ([{sunset(0)} | WE]) (set funk_kette on-till-overnight *{sunrise(0)}) DOELSE (set funk_kette off)");
      fhem("attr funk_kette_an_aus room A4");
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
    }
    case "b"  {    
      fhem("defmod wlan_kette_an_aus DOIF ([{sunset(0)}]) (set wlan_kette on-till-overnight *{sunrise(0)})");
      fhem("attr wlan_kette_an_aus room A4");
    }
    case "c"  {
        fhem("defmod wlan_kette_an_aus DOIF ([07:30:00|AT] and ([sunrise_abs(0)] > [07:30:00])) (set wlan_kette off) DOELSEIF ([{sunset(0)}]) (set wlan_kette on-till-overnight *{sunrise(0)})");
        fhem("attr wlan_kette_an_aus room A4");
    }
    case "d"  {
      fhem("defmod wlan_kette_an_aus DOIF ([17:00-07:00|AT] and [\"^iPhone.*:present\"]) (set wlan_kette on) DOELSEIF ([{sunset(0)} | WE]) (set wlan_kette on-till-overnight *{sunrise(0)}) DOELSE (set wlan_kette off)");
      fhem("attr wlan_kette_an_aus room A4");
    }
  }
}

1;
