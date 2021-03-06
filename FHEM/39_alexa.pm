
# $Id: 39_alexa.pm 23820 2021-02-24 19:29:15Z justme1968 $

package main;

use strict;
use warnings;
use FHEM::Meta;

use CoProcess;

use JSON;
use Data::Dumper;

use POSIX;
use Socket;

use vars qw(%modules);
use vars qw(%defs);
use vars qw(%attr);
use vars qw($readingFnAttributes);
use vars qw($FW_ME);

sub Log($$);
sub Log3($$$);

sub
alexa_Initialize($)
{
  my ($hash) = @_;

  $hash->{ReadFn}   = "alexa_Read";

  $hash->{DefFn}    = "alexa_Define";
  $hash->{NotifyFn} = "alexa_Notify";
  $hash->{RenameFn} = "alexa_Rename";
  $hash->{UndefFn}  = "alexa_Undefine";
  $hash->{DelayedShutdownFn} = "alexa_DelayedShutdownFn";
  $hash->{ShutdownFn} = "alexa_Shutdown";
  $hash->{SetFn}    = "alexa_Set";
  $hash->{GetFn}    = "alexa_Get";
  $hash->{AttrFn}   = "alexa_Attr";
  $hash->{AttrList} = "alexaMapping:textField-long alexaTypes:textField-long fhemIntents:textField-long ".
                      "articles prepositions ".
                      "echoRooms:textField-long ".
                      "persons:textField-long ".
                      "alexaConfirmationLevel:2,1,0 alexaStatusLevel:2,1 ".
                      "skillId:textField ".
                      "alexaFHEM-cmd ".
                      "alexaFHEM-config ".
                      "alexaFHEM-home ".
                      "alexaFHEM-log ".
                      "alexaFHEM-params ".
                      "alexaFHEM-auth ".
                      #"alexaFHEM-filter ".
                      "alexaFHEM-host alexaFHEM-sshUser ".
                      "nrarchive ".
                      "disable:1,0 disabledForIntervals ".
                      $readingFnAttributes;

  $hash->{FW_detailFn} = "alexa_detailFn";
  $hash->{FW_deviceOverview} = 1;

  return FHEM::Meta::InitMod( __FILE__, $hash );
}

#####################################

sub
alexa_AttrDefaults($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};

  if( !AttrVal( $name, 'alexaMapping', undef ) ) {
    CommandAttr(undef,"$name alexaMapping #Characteristic=<name>=<value>,...\n".
                                         "On=verb=schalte,valueOn=an;ein,valueOff=aus,valueToggle=um\n\n".

                                         "Brightness=verb=stelle,property=helligkeit,valuePrefix=auf,values=AMAZON.NUMBER,valueSuffix=prozent\n\n".

                                         "Hue=verb=stelle,valuePrefix=auf,values=rot:0;gr??n:128;blau:200\n".
                                         "Hue=verb=f??rbe,values=rot:0;gr??n:120;blau:220\n\n".

                                         "Saturation=verb=stelle,property=s??ttigung,valuePrefix=auf,values=AMAZON.NUMBER\n".
                                         "Saturation=verb=s??ttige,values=AMAZON.NUMBER\n\n".

                                         "TargetPosition=verb=mach,articles=den;die,values=auf:100;zu:0\n".
                                         "TargetPosition=verb=stelle,valuePrefix=auf,values=AMAZON.NUMBER,valueSuffix=prozent\n\n".

                                         "TargetTemperature=verb=stelle,valuePrefix=auf,values=AMAZON.NUMBER,valueSuffix=grad\n\n".

                                         "Volume:verb=stelle,valuePrefix=auf,values=AMAZON.NUMBER,valueSuffix=prozent\n\n".

                                         "#Weckzeit=verb=stelle,valuePrefix=auf;f??r,values=AMAZON.TIME,valueSuffix=uhr" );
  }

  if( !AttrVal( $name, 'alexaTypes', undef ) ) {
    CommandAttr(undef,"$name alexaTypes #Type=<alias>[,<alias2>[,...]]\n".
                                       "light=licht,lampen\n".
                                       "blind=rolladen,roll??den,jalousie,jalousien,rollo,rollos" );
  }

  if( !AttrVal( $name, 'echoRooms', undef ) ) {
    CommandAttr(undef,"$name echoRooms #<deviceId>=<room>\n" );
  }

  if( !AttrVal( $name, 'persons', undef ) ) {
    CommandAttr(undef,"$name persons #<personId>=<name>\n" );
  }


  if( !AttrVal( $name, 'fhemIntents', undef ) ) {
    CommandAttr(undef,"$name fhemIntents #IntentName=<sample utterance>\n".
                                        "gutenMorgen=guten morgen\n".
                                        "guteNacht=gute nacht" );
  }

}

sub
alexa_InitLog($) {
  my $name = shift;
  if( $attr{global}{logdir} ) {
    CommandAttr(undef, "$name alexaFHEM-log %L/alexa-%Y-%m-%d.log") if( !AttrVal($name, 'alexaFHEM-log', undef ) );
  } else {
    CommandAttr(undef, "$name alexaFHEM-log ./log/alexa-%Y-%m-%d.log") if( !AttrVal($name, 'alexaFHEM-log', undef ) );
  }
}

sub
alexa_Define($$)
{
  my ($hash, $def) = @_;

  my @a = split("[ \t][ \t]*", $def);

  return $@ unless ( FHEM::Meta::SetInternals($hash) );
  #our $VERSION = FHEM::Meta::Get( $hash, 'version' );
  #Log 1, $VERSION;

  return "Usage: define <name> alexa"  if(@a != 2);

  my $name = $a[0];
  $hash->{NAME} = $name;

  my $d = $modules{$hash->{TYPE}}{defptr};
  return "$hash->{TYPE} device already defined as $d->{NAME}." if( defined($d) && $name ne $d->{NAME} );
  $modules{$hash->{TYPE}}{defptr} = $hash;

  addToAttrList("$hash->{TYPE}Name");
  addToAttrList("$hash->{TYPE}Room");
  addToAttrList("$hash->{TYPE}ProactiveEvents:1,0");

  alexa_AttrDefaults($hash);

  $hash->{NOTIFYDEV} = "global,global:npmjs.*alexa-fhem.*";

  #CommandAttr(undef, "$name alexaFHEM-filter alexaName=..*") if( !AttrVal($name, 'alexaFHEM-filter', undef ) );

  if( !AttrVal($name, 'devStateIcon', undef ) ) {
    CommandAttr(undef, "$name stateFormat alexaFHEM");
    CommandAttr(undef, "$name devStateIcon stopped:control_home\@red:start stopping:control_on_off\@orange running.*:control_on_off\@green:stop")
  }

  $hash->{CoProcess} = {  name => 'alexaFHEM',
                         cmdFn => 'alexa_getCMD',
                       };

  if( $init_done ) {
    alexa_InitLog($name);
    CoProcess::start($hash);
  } else {
    $hash->{STATE} = 'active';
  }

  return undef;
}

sub
alexa_Notify($$)
{
  my ($hash,$dev) = @_;

  return if($dev->{NAME} ne "global");

  if( grep(m/^npmjs:BEGIN.*alexa-fhem.*/, @{$dev->{CHANGED}}) ) {
    CoProcess::stop($hash);
    return undef;

  } elsif( grep(m/^npmjs:FINISH.*alexa-fhem.*/, @{$dev->{CHANGED}}) ) {
    CoProcess::start($hash);
    return undef;

  } elsif( grep(m/^INITIALIZED|REREADCFG$/, @{$dev->{CHANGED}}) ) {
    alexa_InitLog($hash->{NAME});
    CoProcess::start($hash);
    return undef;
  }

  return undef;
}

sub
alexa_Rename($$)
{
  my ($new_name, $old_name) = @_;
  my $hash = $defs{$new_name};

  alexa_Set($hash, $new_name, 'restart' );
}

sub
alexa_Undefine($$)
{
  my ($hash, $name) = @_;

  if( $hash->{PID} ) {
    $hash->{undefine} = 1;
    $hash->{undefine} = $hash->{CL} if( $hash->{CL} );

    $hash->{reason} = 'delete';
    CoProcess::stop($hash);

    return "$name will be deleted after alexa-fhem has stopped or after 5 seconds. whatever comes first.";
  }

  delete $modules{$hash->{TYPE}}{defptr};

  return undef;
}
sub
alexa_DelayedShutdownFn($)
{
  my ($hash) = @_;

  if( $hash->{PID} ) {
    $hash->{shutdown} = 1;
    $hash->{shutdown} = $hash->{CL} if( $hash->{CL} );

    $hash->{reason} = 'shutdown';
    CoProcess::stop($hash);

    return 1;
  }

  return undef;
}
sub
alexa_Shutdown($)
{
  my ($hash) = @_;

  CoProcess::terminate($hash);

  delete $modules{$hash->{TYPE}}{defptr};

  return undef;
}

sub
alexa_detailFn($$$$)
{
  my ($FW_wname, $d, $room, $pageHash) = @_; # pageHash is set for summaryFn.
  my $hash = $defs{$d};
  my $name = $hash->{NAME};

  my $ret;

  my $logfile = AttrVal($name, 'alexaFHEM-log', 'FHEM' );
  if( $logfile && $logfile ne 'FHEM' ) {
    my $name = 'alexaFHEMlog';
    $ret .= "<a href=\"$FW_ME?detail=$name\">". AttrVal($name, "alias", "Logfile") ."</a><br>";
  }

  return $ret;
}

sub
alexa_Read($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};

  my $buf = CoProcess::readFn($hash);
  return undef if( !$buf );

  my $data = $hash->{helper}{PARTIAL};
  $data .= $buf;

  while($data =~ m/\n/) {
    ($buf,$data) = split("\n", $data, 2);

    Log3 $name, 5, "$name: read: $buf";

    if( $buf =~ m/^\*\*\* ([^\s]+) (.+)/ ) {
      my $service = $1;
      my $message = $2;

      if( $service eq 'FHEM:' ) {
        if( $message =~ m/^connection failed(: (.*))?/ ) {
          my $reason = $2;

          $hash->{reason} = 'failed to connect to fhem';
          $hash->{reason} .= ": $reason" if( $reason );
          CoProcess::stop($hash);
        }
      }
    }
  }

  $hash->{PARTIAL} = $data;

  return undef;
}

sub
alexa_getLocalIP()
{
  my $socket = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => '8.8.8.8:53',    # google dns
        #PeerAddr    => '198.41.0.4:53', # a.root-servers.net
    );
  return '<unknown>' if( !$socket );

  my $ip = $socket->sockhost;
  close( $socket );

  return $ip if( $ip );

  #$ip = inet_ntoa( scalar gethostbyname( hostname() || 'localhost' ) );
  #return $ip if( $ip );

  return '<unknown>';
}
sub
alexa_configDefault($;$)
{
  my ($hash,$force) = @_;
  my $name = $hash->{NAME};

  my $json;
  my $fh;

  my $configfile = $attr{global}{configfile};
  $configfile = substr( $configfile, 0, rindex($configfile,'/')+1 );
  $configfile .= 'alexa-fhem.cfg';

  local *alexa_readAndBackup = sub() {
    if( -e $configfile ) {
      my $json;
      if( open( my $fh, "<$configfile") ) {
        Log3 $name, 3, "$name: found old config at $configfile";

        local $/;
        $json = <$fh>;
        close( $fh );
      } else {
        Log3 $name, 2, "$name: can't read $configfile";
      }

      if( rename( $configfile, $configfile.".previous" ) ) {
        Log3 $name, 4, "$name: renamed $configfile to $configfile.previous";
      } else {
        Log3 $name, 2, "$name: could not rename $configfile to $configfile.previous :$!";
      }

      return $json;
    }
  };

  $json = alexa_readAndBackup();
  if( !open( $fh, ">$configfile") ) {
    Log3 $name, 2, "$name: can't write $configfile";

    $configfile = $attr{global}{statefile};
    $configfile = substr( $configfile, 0, rindex($configfile,'/')+1 );
    $configfile .= 'alexa-fhem.cfg';

    $json = alexa_readAndBackup();
    if( !open( $fh, ">$configfile") ) {
      Log3 $name, 2, "$name: can't write $configfile";
      $configfile = '/tmp/alexa-fhem.cfg';

      $json = alexa_readAndBackup();
      if( !open( $fh, ">$configfile") ) {
        Log3 $name, 2, "$name: can't write $configfile";

        return "";
      }
    }
  }

  if( $fh ) {
    my $ssh = qx( which ssh ); chomp( $ssh );
    $ssh = '<unknown>' if ( !$ssh );

    my $ip = '127.0.0.1';
    if( AttrVal($name, 'alexaFHEM-host', undef ) ) {
      $ip = alexa_getLocalIP();
    }

    my $conf;
    $conf = eval { decode_json($json) } if( $json && !$force );

    if( 1 || !$conf->{sshproxy} ) {
      $conf->{sshproxy} = { description => 'FHEM Connector',
                                    ssh => $ssh,
                          };
    }

    $conf->{connections} = [{}] if( !$conf->{connections} );
    $conf->{connections}[0]->{name} = 'FHEM' if( !$conf->{connections}[0]->{name} );
    $conf->{connections}[0]->{server} = $ip if( !$conf->{connections}[0]->{server} );
    #$conf->{connections}[0]->{proactiveEvents} = JSON::false if( !$conf->{connections}[0]->{proactiveEvents} );
    $conf->{connections}[0]->{filter} = 'alexaName=..*' if( !$conf->{connections}[0]->{filter} );
    $conf->{connections}[0]->{uid} = $< if( $conf->{sshproxy} );

    my $web = $defs{WEB};
    if( !$web ) {
      if( my @names = devspec2array('TYPE=FHEMWEB:FILTER=TEMPORARY!=1') ) {
        $web = $defs{$names[0]} if( defined($defs{$names[0]}) );

        Log3 $name, 4, "$name: using $names[0] as FHEMWEB device." if( $web );
      }
    } else {
      Log3 $name, 4, "$name: using WEB as FHEMWEB device." if( $web );
    }

    if( $web ) {
      $conf->{connections}[0]->{port} = $web->{PORT} if( !$conf->{connections}[0]->{port} );
      $conf->{connections}[0]->{webname} = AttrVal( 'WEB', 'webname', 'fhem' ) if( !$conf->{connections}[0]->{webname} );
    } else {
      Log3 $name, 2, "$name: no FHEMWEB device found. please adjust config file manualy.";
    }

    $json = JSON->new->pretty->utf8->encode($conf);
    print $fh $json;
    close( $fh );

    if( index($configfile,'/') == 0 ) {
      system( "ln -sf $configfile $attr{global}{modpath}/FHEM/alexa-fhem.cfg" );
    } else {
      system( "ln -sf `pwd`/$configfile $attr{global}{modpath}/FHEM/alexa-fhem.cfg" );
    }
  }

  $configfile = "./$configfile" if( index($configfile,'/') == -1 );

  Log3 $name, 2, "$name: created default configfile: $configfile";

  CommandAttr(undef, "$name alexaFHEM-config $configfile") if( !AttrVal($name, 'alexaFHEM-config', undef ) );

  CommandSave(undef,undef) if( AttrVal( "autocreate", "autosave", 1 ) );

  return $configfile;
}

sub
alexa_getCMD($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};

  return undef if( !$init_done );

  my $key = ReadingsVal($name, 'alexaFHEM.skillRegKey', undef);
  if( !$key ) {
    my $key = getKeyValue('alexaFHEM.skillRegKey');
    readingsSingleUpdate($hash, 'alexaFHEM.skillRegKey', $key, 1 ) if( $key );
  } elsif( $key !~ m/^crypt:/ ) {
    fhem( "set $name proxyKey $key" );
  }
  my $token = ReadingsVal($name, 'alexaFHEM.bearerToken', undef);
  if( !$token ) {
    my $token = getKeyValue('alexaFHEM.bearerToken');
    readingsSingleUpdate($hash, 'alexaFHEM.bearerToken', $token, 1 ) if( $token );
  } elsif( $token !~ m/^crypt:/ ) {
    fhem( "set $name proxyToken $token" );
  }

  if( !AttrVal($name, 'alexaFHEM-config', undef ) ) {
    alexa_configDefault($hash);
  }

  return undef if( IsDisabled($name) );
  #return undef if( ReadingsVal($name, 'alexaFHEM', 'unknown') =~ m/^running/ );


  my $ssh_cmd;
  if( my $host = AttrVal($name, 'alexaFHEM-host', undef ) ) {
    my $ssh = qx( which ssh ); chomp( $ssh );
    if( my $user = AttrVal($name, 'alexaFHEM-sshUser', undef ) ) {
      $ssh_cmd = "$ssh $user\@$host";
    } else {
      $ssh_cmd = "$ssh $host";
    }

    Log3 $name, 3, "$name: using ssh cmd $ssh_cmd";
  }

  my $cmd;
  if( $ssh_cmd ) {
    $cmd = AttrVal( $name, "alexaFHEM-cmd", qx( $ssh_cmd which alexa-fhem ) );
  } else {
    $cmd = AttrVal( $name, "alexaFHEM-cmd", qx( which alexa-fhem ) );
  }
  chomp( $cmd );

  if( !$ssh_cmd && !(-X $cmd) ) {
    my $msg = "alexa-fhem not installed. install with 'sudo npm install -g alexa-fhem'.";
    $msg = "$cmd does not exist" if( $cmd );
    return (undef, $msg);
  }

  $cmd = "$ssh_cmd $cmd" if( $ssh_cmd );

  if( my $home = AttrVal($name, 'alexaFHEM-home', undef ) ) {
    $home = $ENV{'PWD'} if( $home eq 'PWD' );
    $ENV{'HOME'} = $home;
    Log3 $name, 2, "$name: setting \$HOME to $home";
  }
  if( my $config = AttrVal($name, 'alexaFHEM-config', undef ) ) {
    if( $ssh_cmd ) {
      qx( $ssh_cmd "cat > /tmp/alexa-fhem.cfg" < $config );
      $cmd .= " -c /tmp/alexa-fhem.cfg";
    } else {
      $cmd .= " -c $config";
    }
  }
  if( my $auth = AttrVal($name, 'alexaFHEM-auth', undef ) ) {
    $auth = alexa_decrypt( $auth );
    $cmd .= " -a $auth";
  }
  if( my $ssl = AttrVal('WEB', "HTTPS", undef ) ) {
    $cmd .= " -s";
  }
  if( my $params = AttrVal($name, 'alexaFHEM-params', undef ) ) {
    $cmd .= " $params";
  }

  if( AttrVal( $name, 'verbose', 3 ) == 5 ) {
    Log3 $name, 2, "$name: starting alexa-fhem: $cmd";
  } else {
    my $msg = $cmd;
    $msg =~ s/-a\s+[^:]+:[^\s]+/-a xx:xx/g;
    Log3 $name, 2, "$name: starting alexa-fhem: $msg";
  }

  return $cmd;

}

sub
alexa_Set($$@)
{
  my ($hash, $name, $cmd, @args) = @_;

  my $list = "add createDefaultConfig:noArg reload:noArg skillId";

  if( $cmd eq 'reload' ) {
    $hash->{".triggerUsed"} = 1;
    if( @args ) {
      FW_directNotify($name, "reload $args[0]");
    } else {
      FW_directNotify($name, 'reload');
    }

    return undef;

  } elsif( $cmd eq 'add' ) {
    return "usage: set $name $cmd <name>" if( !@args );
    $hash->{".triggerUsed"} = 1;

    FW_directNotify($name, "reload $args[0]");

    return undef;

  } elsif( $cmd eq 'execute' ) {
    my ($intent,$applicationId) = split(':', shift @args, 2 );
    return 'usage $cmd execute <intent> [json]' if( !$intent );

    my $json = join(' ',@args);
    my $decoded = eval { decode_json($json) };
    if( $@ ) {
      my $msg = "json error: $@ in $json";
      Log3 $name, 2, "$name: $msg";
      return $msg;
    }
    Log3 $name, 5, "$name: \"$json\" -> ". Dumper $decoded;

    my $cmd = '{Log 1, "test"; return "result";}';
    Log3 $name, 5, "$name: cmd: $cmd";

    if( ref($decoded->{slots}) eq 'HASH' ) {
      $hash->{active} = 1;
      my $intent = $intent;
      $intent = "$intent:$applicationId" if( $applicationId );
      readingsSingleUpdate($hash, 'fhemIntent', $intent, 1 );
      my $exec = EvalSpecials($cmd, %{$decoded->{slots}});
      Log3 $name, 5, "$name: exec: $exec";
      my $ret = AnalyzeCommandChain($hash, $exec);
      Log3 $name, 5, "$name: ret ". ($ret?$ret:"undefined");
      $hash->{active} = 0;

      return $ret;
    }

    return undef;
  } elsif( $cmd eq 'skillId' ) {

    return CommandAttr(undef,"$name skillId $args[0]" );

  } elsif( $cmd eq 'createDefaultConfig' ) {
    my $force = 0;
    $force = 1 if( $args[0] && $args[0] eq 'force' );
    my $config = alexa_configDefault($hash, $force);

    return "created default config: $config";

  } elsif( $cmd eq 'proxyKey' ) {
    return "usage: set $name $cmd <key>" if( !@args );
    my $key = $args[0];

    $hash->{".triggerUsed"} = 1;

    $key = alexa_encrypt($key);
    setKeyValue('alexaFHEM.skillRegKey', $key );
    readingsSingleUpdate($hash, 'alexaFHEM.skillRegKey', $key, 1 );

    CommandSave(undef,undef) if( AttrVal( "autocreate", "autosave", 1 ) );

    return undef;

  } elsif( $cmd eq 'proxyToken' ) {
    return "usage: set $name $cmd <key>" if( !@args );
    my $token = $args[0];

    $hash->{".triggerUsed"} = 1;

    $token = alexa_encrypt($token);
    setKeyValue('alexaFHEM.bearerToken', $token );
    readingsSingleUpdate($hash, 'alexaFHEM.bearerToken', $token, 1 );

    CommandSave(undef,undef) if( AttrVal( "autocreate", "autosave", 1 ) );

    return undef;

  } elsif( $cmd eq 'clearProxyCredentials' ) {
    setKeyValue('alexaFHEM.skillRegKey', undef );
    setKeyValue('alexaFHEM.bearerToken', undef );

    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, 'alexaFHEM.skillRegKey', '', 1 );
    readingsBulkUpdate($hash, 'alexaFHEM.bearerToken', '', 1 );
    readingsEndUpdate($hash,1);

    CommandSave(undef,undef) if( AttrVal( "autocreate", "autosave", 1 ) );

    FW_directNotify($name, 'clearProxyCredentials');

    return undef;

  } elsif( $cmd eq 'unregister' ) {
    FW_directNotify($name, 'unregister');

    fhem( "set $name clearProxyCredentials" );

    CommandAttr( undef, '$name disable 1' );

    CommandSave(undef,undef) if( AttrVal( "autocreate", "autosave", 1 ) );

    return undef;
  }

  return CoProcess::setCommands($hash, $list, $cmd, @args);

  return "Unknown argument $cmd, choose one of $list";
}



sub
alexa_Get($$@)
{
  my ($hash, $name, $cmd) = @_;

  my $list = "customSlotTypes:noArg interactionModel:noArg skillId:noArg proxyKey:noArg";

  if( lc($cmd) eq 'customslottypes' ) {
    if( $hash->{CL} ) {
      FW_directNotify($name, "customSlotTypes $hash->{CL}{NAME}");
    } else {
      FW_directNotify($name, 'customSlotTypes');
    }

    return undef;

  } elsif( lc($cmd) eq 'interactionmodel' ) {
    my %mappings;
    if( my $mappings = AttrVal( $name, 'alexaMapping', undef ) ) {
      foreach my $mapping ( split( / |\n/, $mappings ) ) {
        next if( !$mapping );
        next if( $mapping =~ /^#/ );

        my %characteristic;
        my ($characteristic, $remainder) = split( /:|=/, $mapping, 2 );
        if( $characteristic =~ m/([^.]+)\.([^.]+)/ ) {
          $characteristic = $1;
          $characteristic{device} = $2;
        }

        my @parts = split( /,/, $remainder );
        foreach my $part (@parts) {
          my @p = split( '=', $part );
          if( $p[1] =~ m/;/ ) {
            $p[1] =~ s/\+/ /g;
            my @values = split(';', $p[1]);
            my @values2 = grep {$_ ne ''} @values;

            $characteristic{$p[0]} = \@values2;

            if( scalar @values != scalar @values2 ) {
              $characteristic{"_$p[0]"} = \@values;
              $characteristic{$p[0]} = $values2[0] if( scalar @values2 == 1 );
            }
          } else {
            $p[1] =~ s/\+/ /g;
            $characteristic{$p[0]} = $p[1];
          }
        }

        $mappings{$characteristic} = [] if( !$mappings{$characteristic} );
        push @{$mappings{$characteristic}}, \%characteristic;
      }
    }
#Log 1, Dumper \%mappings;

    my %types;
    if( my $entries = AttrVal( $name, 'alexaTypes', undef ) ) {
      sub append($$$) {
        my($a, $c, $v) = @_;

        if( !defined($a->{$c}) ) {
          $a->{$c} = {};
        }
        $a->{$c}{$v} = 1;
      }

      sub merge($$) {
       my ($a, $b) = @_;
       return $a if( !defined($b) );

       my @result = ();

       if( ref($b) eq 'ARRAY' ) {
         @result = sort keys %{{map {((split(':',$_,2))[0] => 1)} (@{$a}, @{$b})}};
       } else {
         push @{$a}, $b;
         return $a;
       }

       return \@result;
     }

      foreach my $entry ( split( / |\n/, $entries ) ) {
        next if( !$entry );
        next if( $entry =~ /^#/ );

        my ($type, $remainder) = split( /:|=/, $entry, 2 );
        $types{$type} = [];
        my @names = split( /,/, $remainder );
        foreach my $name (@names) {
          push @{$types{$type}}, $name;
        }
      }
    }

    my $verbsOfIntent = {};
    my $intentsOfVerb = {};
    my $valuesOfIntent = {};
    my $intentsOfCharacteristic = {};
    my $characteristicsOfIntent = {};
    foreach my $characteristic ( keys %mappings ) {
      my $mappings = $mappings{$characteristic};
      $mappings = [$mappings] if( ref($mappings) ne 'ARRAY');
      my $i = 0;
      foreach my $mapping (@{$mappings}) {
        if( !$mapping->{verb} ) {
          Log3 $name, 2, "alexaMapping: no verb given for $characteristic characteristic";
          next;
        }

        $mapping->{property} = '' if( !$mapping->{property} );
        $mapping->{property} = [$mapping->{property}] if( ref($mapping->{property}) ne 'ARRAY' );
        foreach my $property (@{$mapping->{property}}) {
          my $intent = $characteristic;
          $intent = lcfirst($mapping->{valueSuffix}) if( !$property && $mapping->{valueSuffix} );
          $intent .= 'Intent';

          my $values = [];
          $values = merge( $values, $mapping->{values} );
          $values = merge( $values, $mapping->{valueOn} );
          $values = merge( $values, $mapping->{valueOff} );
          $values = merge( $values, $mapping->{valueToggle} );

          append($verbsOfIntent, $intent, $mapping->{verb} );
          append($intentsOfVerb, $mapping->{verb}, $intent );
          append($valuesOfIntent, $intent, join( ',', @{$values} ) );
          append($intentsOfCharacteristic, $characteristic, $intent );
          append($characteristicsOfIntent, $intent, $characteristic );
        }
      }
    }
Log 1, Dumper $verbsOfIntent;
Log 1, Dumper $intentsOfVerb;
Log 1, Dumper $valuesOfIntent;
Log 1, Dumper $intentsOfCharacteristic;
Log 1, Dumper $characteristicsOfIntent;

    my $intents = {};
    my $schema = { intents => [] };
    my $types = {};
    $types->{FHEM_article} = [split( /,|;/, AttrVal( $name, 'articles', 'der,die,das,den' ) ) ];
    $types->{FHEM_preposition} = [split( /,|;/, AttrVal( $name, 'prepositions', 'in,im,in der' ) ) ];
    my $samples = '';
    foreach my $characteristic ( keys %mappings ) {
      my $mappings = $mappings{$characteristic};
      $mappings = [$mappings] if( ref($mappings) ne 'ARRAY');
      my $i = 0;
      foreach my $mapping (@{$mappings}) {
        if( !$mapping->{verb} ) {
          Log3 $name, 2, "alexaMapping: no verb given for $characteristic characteristic";
          next;
        }

        my $values = [];
        $values = merge( $values, $mapping->{values} );
        $values = merge( $values, $mapping->{valueOn} );
        $values = merge( $values, $mapping->{valueOff} );
        $values = merge( $values, $mapping->{valueToggle} );

        $mapping->{property} = '' if( !$mapping->{property} );
        $mapping->{property} = [$mapping->{property}] if( ref($mapping->{property}) ne 'ARRAY' );
        foreach my $property (@{$mapping->{property}}) {

          my $nr = $i?chr(65+$i):'';
          $nr = '' if( $mapping->{valueSuffix} );
          #my $intent = $characteristic .'Intent'. $nr;
          my $intent = $characteristic;
          $intent = lcfirst($mapping->{valueSuffix}) if( !$property && $mapping->{valueSuffix} );
          $intent .= 'Intent';
          $intent .= $nr;


          next if( $intents->{$intent} );
          $intents->{$intent} = 1;

          my $slots = [];
          my $samples2 = [];
          push @{$slots}, { name => 'article', type => 'FHEM_article' };
          push @{$slots}, { name => 'Device', type => 'FHEM_Device' } if( !$mapping->{device} );
          push @{$slots}, { name => 'preposition', type => 'FHEM_preposition' };
          push @{$slots}, { name => 'Room', type => 'FHEM_Room' };
          if( ref($mapping->{valuePrefix}) eq 'ARRAY' ) {
            push @{$slots}, { name => "${characteristic}_valuePrefix$nr", type => "${characteristic}_prefix$nr" };
            $types->{"${characteristic}_prefix$nr"} = $mapping->{valuePrefix};
          }
          my $slot_name = "${characteristic}_Value$nr";
          $slot_name = lcfirst($mapping->{valueSuffix})."_Value$nr" if( !$property && $mapping->{valueSuffix} );
          if( $mapping->{values} && $mapping->{values} =~ /^AMAZON/ ) {
            push @{$slots}, { name => $slot_name, type => $mapping->{values} };
          } else {
            push @{$slots}, { name => $slot_name, type => "${characteristic}_Value$nr" };
            $types->{$slot_name} = $values if( $values->[0] );
          }
          if( ref($mapping->{valueSuffix}) eq 'ARRAY' ) {
            push @{$slots}, { name => "${characteristic}_valueSuffix$nr", type => "${characteristic}_suffix$nr" };
            $types->{"${characteristic}_suffix"} = $mapping->{valueSuffix$nr};
          }

          if( ref($mapping->{articles}) eq 'ARRAY' ) {
            $types->{"${characteristic}_article$nr"} = $mapping->{articles};
          }

          $mapping->{verb} = [$mapping->{verb}] if( ref($mapping->{verb}) ne 'ARRAY' );
          foreach my $verb (@{$mapping->{verb}}) {
            $samples .= "\n" if( $samples );

            my @articles = ('','{article}');
            if( ref($mapping->{articles}) eq 'ARRAY' ) {
              $articles[1] = "{${characteristic}_article}";
            } elsif( $mapping->{articles} ) {
              @articles = ($mapping->{articles});
            }
            foreach my $article (@articles) {
              foreach my $room ('','{Room}') {
                my $line;

                $line .= "$intent $verb";
                $line .= " $property" if( $property );
                $line .= " $article" if( $article );
                $line .= $mapping->{device}?" $mapping->{device}":' {Device}';
                $line .= " {preposition} $room" if( $room );
                if( ref($mapping->{valuePrefix}) eq 'ARRAY' ) {
                  $line .= " {${characteristic}_valuePrefix$nr}";
                } else {
                  $line .= " $mapping->{valuePrefix}" if( $mapping->{valuePrefix} );
                }
                $line .= " {$slot_name}";
                if( ref($mapping->{_valueSuffix}) eq 'ARRAY' ) {
                  $line .= "\n$line";
                }
                if( ref($mapping->{valueSuffix}) eq 'ARRAY' ) {
                  $line .= " {${characteristic}_valueSuffix$nr}";
                } else {
                  $line .= " $mapping->{valueSuffix}" if( $mapping->{valueSuffix} );
                }

                push @{$samples2}, $line;

                $samples .= "\n" if( $samples );
                $samples .= $line;
              }
            }
          }
          push @{$schema->{intents}}, {intent => $intent, slots => $slots};
          #push @{$schema->{intents}}, {intent => $intent, slots => $slots, samples => $samples2};
        }

        ++$i;
      }
      $samples .= "\n";
    }

    if( my $entries = AttrVal( $name, 'fhemIntents', undef ) ) {
      my %intents;
      foreach my $entry ( split( /\n/, $entries ) ) {
        next if( !$entry );
        next if( $entry =~ /^#/ );

        my $slots = [];

        my ($intent, $remainder) = split( /:|=/, $entry, 2 );
        my @parts = split( /,/, $remainder );
        my $utterance = $parts[$#parts];

        my $intent_name = "FHEM${intent}Intent";
        if( $intent =~ m/^(set|get|attr)\s/ ) {
          $intent_name = "FHEM${1}Intent";
          my $i = 1;
          while( defined($intents{$intent_name}) ) {
            $intent_name = "FHEM${1}Intent".chr(65+$i);
            ++$i;
          }
        } elsif( $intent =~ m/^{.*}$/ ) {
          $intent_name = 'FHEMperlCodeIntent';
          my $nr = '';
          my $i = 1;
          while( defined($intents{$intent_name}) ) {
            if( $i < 26 ) {
              $nr = chr(65+$i);
            } else {
              $nr = chr(64+int($i/26)).chr(65+$i%26);
            }
            ++$i;
            $intent_name = "FHEMperlCodeIntent$nr";
          }

          my $slot_names = {};
          my $u = $utterance;
          while( $u =~ /\{(.*?)\}/g ) {
            my $slot = $1;
            my ($name, $values) = split( /:|=/, $slot, 2 );

            my $slot_name = "${intent_name}_${name}";
            next if( $slot_names->{$slot_name} );
            $slot_names->{$slot_name} = 1;

            if( $values ) {
              if( $values && $values =~ /^AMAZON/ ) {
                push @{$slots}, { name => $slot_name, type => $values };
              } else {
                push @{$slots}, { name => $slot_name, type => "${intent_name}_${name}_Value" };
                $values =~ s/\+/ /g;
                my @values = split(';', $values );
                $types->{"${intent_name}_${name}_Value"} = \@values if( $values[0] );
              }

              $slot =~ s/\+/\\\+/g;
              $utterance =~ s/\{$slot\}/\{$slot_name\}/;

            } else {
              push @{$slots}, { name => $name, type => "FHEM_$name" };

            }
          }

        }
        $intent_name =~ s/ //g;
        $intents{$intent_name} = $intent;

        if( @{$slots} ) {
          push @{$schema->{intents}}, {intent => $intent_name, slots => $slots };
        } else {
          push @{$schema->{intents}}, {intent => $intent_name };
        }

        foreach my $u ( split( '\|', $utterance ) ) {
          $samples .= "\n$intent_name $u";
        }
      }
      $samples .= "\n";
    }

    push @{$schema->{intents}}, {intent => "StatusIntent",
                                 slots => [ { name => 'Device', type => 'FHEM_Device' },
                                            { name => 'preposition', type => 'FHEM_preposition' },
                                            { name => 'Room', type => 'FHEM_Room' } ]};
    push @{$schema->{intents}}, {intent => "RoomAnswerIntent",
                                 slots => [ { name => 'preposition', type => 'FHEM_preposition' },
                                            { name => 'Room', type => 'FHEM_Room' } ]};
    push @{$schema->{intents}}, {intent => "RoomListIntent", };
    push @{$schema->{intents}}, {intent => "DeviceListIntent",
                                 slots => [ { name => 'article', type => 'FHEM_article' },
                                            { name => 'Room', type => 'FHEM_Room' } ]};
    push @{$schema->{intents}}, {intent => "AMAZON.CancelIntent", };
    push @{$schema->{intents}}, {intent => "AMAZON.StopIntent", };

    $samples .= "\nStatusIntent status";
    $samples .= "\nStatusIntent {Device} status";
    $samples .= "\nStatusIntent status von {Device}";
    $samples .= "\nStatusIntent wie ist der status von {Device}";
    $samples .= "\nStatusIntent wie ist der status {preposition} {Room}";
    $samples .= "\n";

    $samples .= "\nRoomAnswerIntent {preposition} {Room}";
    $samples .= "\n";

    $samples .= "\nRoomListIntent raumliste";
    $samples .= "\nDeviceListIntent ger??teliste";
    $samples .= "\nDeviceListIntent ger??teliste {Room}";
    $samples .= "\nDeviceListIntent ger??teliste f??r {article} {Room}";
    $samples .= "\n";

    my $json = JSON->new;
    $json->pretty(1);

    my $t;
    foreach my $type ( sort keys %{$types} ) {
      $t .= "\n" if( $t );
      $t .= "$type\n  ";
      $t .= join("\n  ", @{$types->{$type}} );
    }

    return "Intent Schema:\n".
           "--------------\n".
           $json->utf8->encode( $schema ) ."\n".
           "Custom Slot Types:\n".
           "------------------\n".
           $t. "\n\n".
           "Sample Utterances:\n".
           "------------------\n".
           $samples.
           "\nreload 39_alexa\n".
           "get alexa interactionmodel\n";

    return undef;
  } elsif( $cmd eq 'skillId' ) {
    my $skillId = AttrVal($name, 'skillId', undef);

    return 'no skillId set' if( !$skillId );

    $skillId = alexa_decrypt( $skillId );

    return "skillId: $skillId";

  } elsif( $cmd eq 'proxyKey' ) {
    my $key = ReadingsVal($name, 'alexaFHEM.skillRegKey', undef);

    return alexa_decrypt($key);

  } elsif( $cmd eq 'proxyToken' ) {
    my $token = ReadingsVal($name, 'alexaFHEM.bearerToken', undef);

    return alexa_decrypt($token);
  }

  return "Unknown argument $cmd, choose one of $list";
}

sub
alexa_Parse($$;$)
{
  my ($hash,$data,$peerhost) = @_;
  my $name = $hash->{NAME};
}

sub
alexa_encrypt($)
{
  my ($decoded) = @_;
  my $key = getUniqueId();

  return "" if( !$decoded );
  return $decoded if( $decoded =~ /^crypt:(.*)/ );

  my $encoded;
  for my $char (split //, $decoded) {
    my $encode = chop($key);
    $encoded .= sprintf("%.2x",ord($char)^ord($encode));
    $key = $encode.$key;
  }

  return 'crypt:'. $encoded;
}
sub
alexa_decrypt($)
{
  my ($encoded) = @_;
  my $key = getUniqueId();

  return "" if( !$encoded );

  $encoded = $1 if( $encoded =~ /^crypt:(.*)/ );

  my $decoded;
  for my $char (map { pack('C', hex($_)) } ($encoded =~ /(..)/g)) {
    my $decode = chop($key);
    $decoded .= chr(ord($char)^ord($decode));
    $key = $decode.$key;
  }

  return $decoded;
}

sub
alexa_Attr($$$)
{
  my ($cmd, $name, $attrName, $attrVal) = @_;

  my $orig = $attrVal;

  my $hash = $defs{$name};
  if( $attrName eq 'disable' ) {
    my $hash = $defs{$name};
    if( $cmd eq "set" && $attrVal ne "0" ) {
      $attrVal = 1;
      CoProcess::stop($hash);

    } else {
      $attr{$name}{$attrName} = 0;
      CoProcess::start($hash);

    }

  } elsif( $attrName eq 'disabledForIntervals' ) {
    $attr{$name}{$attrName} = $attrVal;

    CoProcess::start($hash);

  } elsif( $attrName eq 'skillId' ) {
    if( $cmd eq "set" && $attrVal ) {

      if( $attrVal =~ /^crypt:/ ) {
        return;

      } elsif( $attrVal !~ /(^amzn1\.ask\.skill\.[0-9a-f\-]+)|(^amzn1\.echo-sdk-ams\.app\.[0-9a-f\-]+)/ ) {
        return "$attrVal is not a valid skill id";
      }

      $attrVal = alexa_encrypt($attrVal);

      if( $orig ne $attrVal ) {
        $attr{$name}{$attrName} = $attrVal;
        return "stored obfuscated skillId";
      }
    }

  } elsif( $attrName eq 'alexaFHEM-log' ) {
    if( $cmd eq "set" && $attrVal && $attrVal ne 'FHEM' ) {
      fhem( "defmod -temporary alexaFHEMlog FileLog $attrVal fakelog" );
      CommandAttr( undef, 'alexaFHEMlog room hidden' );
      #if( my $room = AttrVal($name, "room", undef ) ) {
      #  CommandAttr( undef,"alexaFHEMlog room $room" );
      #}
      $hash->{logfile} = $attrVal;
    } else {
      fhem( "delete alexaFHEMlog" );
    }

    $attr{$name}{$attrName} = $attrVal;

    CoProcess::start($hash);

  } elsif( $attrName eq 'alexaFHEM-auth' ) {
    if( $cmd eq "set" && $attrVal ) {
      $attrVal = alexa_encrypt($attrVal);
    }
    $attr{$name}{$attrName} = $attrVal;

    CoProcess::start($hash);

    if( $cmd eq "set" && $orig ne $attrVal ) {
      $attr{$name}{$attrName} = $attrVal;
      return "stored obfuscated auth data";
    }

  } elsif( $attrName eq 'alexaFHEM-params' ) {
    $attr{$name}{$attrName} = $attrVal;

    CoProcess::start($hash);

  } elsif( $attrName eq 'alexaFHEM-host' ) {
    $attr{$name}{$attrName} = $attrVal;

    CoProcess::start($hash);

  } elsif( $attrName eq 'alexaFHEM-sshUser' ) {
    $attr{$name}{$attrName} = $attrVal;

    CoProcess::start($hash);

  }


  if( $cmd eq 'set' ) {
    if( $orig ne $attrVal ) {
      $attr{$name}{$attrName} = $attrVal;
      return "stored modified value";
    }

  } else {
    delete $attr{$name}{$attrName};

    RemoveInternalTimer($hash);
    InternalTimer(gettimeofday(), "alexa_AttrDefaults", $hash, 0);
  }

  return;
}


1;

=pod
=item tag publicAPI
=item summary    Module to control the FHEM/Alexa integration
=item summary_DE Modul zur Konfiguration der FHEM/Alexa Integration
=begin html

<a name="alexa"></a>
<h3>alexa</h3>
<ul>
  Module to control the integration of Amazon Alexa devices with FHEM.<br><br>

  Notes:
  <ul>
    <li>JSON has to be installed on the FHEM host.</li>
    <li>HOWTO for public FHEM Connector skill: <a href='https://wiki.fhem.de/wiki/FHEM_Connector'>FHEM_Connector</a></li>
    <li>HOWTO for privte skills: <a href='https://wiki.fhem.de/wiki/Alexa-Fhem'>alexa-fhem</a></li>
  </ul>

  <a name="alexa_Set"></a>
  <b>Set</b>
  <ul>
    <li>add <name><br>
      Adds the device <code>name</code> to alexa-fhem.
      Will try to send a proacive event to amazon. If this succedes no manual device discovery is needed.
      If this fails you have to you have to manually start a device discovery
      for the home automation skill in the amazon alexa app.</li>

    <li>reload [name]<br>
      Reloads the device <code>name</code> or all devices in alexa-fhem.
      Will try to send a proacive event to amazon. If this succedes no manual device discovery is needed.
      If this fails you have to you have to manually start a device discovery
      for the home automation skill in the amazon alexa app.</li>

    <li>createDefaultConfig<br>
    adds the default config for the sshproxy to the existing config file or creates a new config file. sets the
    alexaFHEM-config attribut if not already set.</li>

    <li>clearProxyCredentials<br>
    clears all stored sshproxy credentials</li>
    <br>
  </ul>

  <a name="alexa_Get"></a>
  <b>Get</b>
  <ul>
    <li>customSlotTypes<br>
      Instructs alexa-fhem to write the device specific Custom Slot Types for the Interaction Model
      configuration to the alexa-fhem console and if possible to the requesting fhem frontend.</li>
    <li>interactionModel<br>
      Get Intent Schema, non device specific Custom Slot Types and Sample Utterances for the Interaction Model
      configuration.</li>
    <li>skillId<br>
      shows the configured skillId.</li>
  </ul>

  <a name="alexa_Attr"></a>
  <b>Attr</b>
  <ul>
    <li>alexaFHEM-auth<br>
      the user:password combination to use to connect to fhem.</li>
    <li>alexaFHEM-cmd<br>
      The command to use as alexa-fhem.</li>
    <li>alexaFHEM-config<br>
      The config file to use for alexa-fhem.</li>
    <li>alexaFHEM-log<br>
      The log file to use for alexa-fhem. For possible %-wildcards see <a href="#FileLog">FileLog</a>.</li>.
    <li>nrarchive<br>
      see <a href="#FileLog">FileLog</a></li>.
    <li>alexaFHEM-params<br>
      Additional alexa-fhem cmdline params.</li>

    <li>alexaName<br>
      The name to use for a device with alexa.</li>

    <br>The following attributes are only relevant for custom skills:

    <li>alexaRoom<br>
      The room name to use for a device with alexa.</li>

    <li>alexaProactiveEvents<br>
      0 -> don't send proactiveEvents to amazon (default)<br>
      1 -> send proactiveEvents to amazon<br>
      devices that send proactiveEvents to amazon can be used to trigger alexa routines.<br>
      setting alexaProactiveEvents to 0 in the alexa device itself will disable all event reporting for this fhem instance</li>
    <li>articles<br>
      defaults to: der,die,das,den</li>
    <li>prepositions<br>
      defaults to: in,im,in der</li>
    <li>alexaMapping<br>
      maps spoken commands to intents for certain characteristics.</li>
    <li>alexaTypes<br>
      maps spoken device types to ServiceClasses. eg: attr alexa alexaTypes light:licht,lampe,lampen blind:rolladen,jalousie,rollo Outlet:steckdose TemperatureSensor:thermometer LockMechanism:schloss OccupancySensor: anwesenheit</li>
    <li>echoRooms<br>
      maps echo devices to default rooms.</li>
    <li>persons<br>
      maps personIds to names.</li>
    <li>fhemIntents<br>
      maps spoken commands directed to fhem as a whole (i.e. not to specific devices) to events from the alexa device.</li>
    <li>alexaConfirmationLevel<br>
      </li>
    <li>alexaStatusLevel<br>
      </li>
    <li>skillId<br>
      skillId to use for automatic interaction model upload (not yet finished !!!)
      </li>
    Note: changes to attributes of the alexa device will automatically trigger a reconfiguration of
          alxea-fhem and there is no need to restart the service.
  </ul>
</ul><br>

=end html

=encoding utf8
=for :application/json;q=META.json 39_alexa.pm
{
  "abstract": "Module to control the FHEM/Alexa integration",
  "x_lang": {
    "de": {
      "abstract": "Modul zur Konfiguration der FHEM/Alexa Integration"
    }
  },
  "keywords": [
    "fhem-mod",
    "fhem-mod-device",
    "alexa",
    "alexa-fhem",
    "nodejs",
    "node"
  ],
  "release_status": "stable",
  "x_fhem_maintainer": [
    "justme1968"
  ],
  "x_fhem_maintainer_github": [
    "justme-1968"
  ],
  "prereqs": {
    "runtime": {
      "requires": {
        "FHEM": 5.00918799,
        "perl": 5.014,
        "Meta": 0,
        "CoProcess": 0,
        "JSON": 0,
        "Data::Dumper": 0
      },
      "recommends": {
      },
      "suggests": {
      }
    }
  },
  "x_prereqs_nodejs": {
    "runtime": {
      "requires": {
        "node": 8.0,
        "alexa-fhem": 0
      },
      "recommends": {
      },
      "suggests": {
      }
    }
  }
}
=end :application/json;q=META.json

=cut
