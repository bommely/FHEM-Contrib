# ##############################################################################
# 
# FHEM module for SMA Energy Meter
# 
# used to read data from the SMA Energy Meter
# ##############################################################################

package main;

use strict;
use warnings;
use IO::Socket::Multicast;

# ##############################################################################
# Initialization routine called at start of FHEM
# ##############################################################################
sub SMA_EM_Initialize($) {
	my ($hash) = @_;
#	$hash->{ReadFn} = "SMA_EM_Read";
#	$hash->{ReadyFn} = "SMA_EM_Ready";
	$hash->{DefFn} = "SMA_EM_Define";
#	$hash->{UndefFn} = "SMA_EM_Undefine";
#	$hash->{GetFn} = "SMA_EM_Get";
#	$hash->{NotifyFn} = "SMA_EM_Notify";
}

# ##############################################################################
# called when a module defined
# ##############################################################################
sub SMA_EM_Define($$) {
	my ($hash, $def) = @_;
	my @a = split(/\s+/, $def);
	my $now  = TimeNow();
	my $serialNumber = $a[2];
	
	$hash->{serialNumber} = $serialNumber;
	#Log3($hash->{NAME}, 5, "Count Parameters: ".int(@a));
	
	InternalTimer(gettimeofday()+1, "SMA_EM_Parse", $hash, 0);
	
	return "Wrong syntax: use define <name> SMA_EM <serialnumber>" if(int(@a) < 3);

	return undef;
}

# ##############################################################################
# called after initialize
# ##############################################################################
sub SMA_EM_Parse($) {
	my ($hash, $a) = @_;
	my $socket;
	my $data;
	$socket = IO::Socket::Multicast->new(LocalPort=>9522);
	$socket->mcast_add('239.12.255.254');
	while(1==1) {
		#listen at multicast port
	
		$socket->recv($data, 600);
	
		readingsBeginUpdate($hash);
		my $serialNumber = SMA_EM_GetData($data, 21, 24);
		readingsBulkUpdate($hash, "PConsumptionAll", SMA_EM_GetData($data, 32, 36, 1)+0/10);
		readingsBulkUpdate($hash, "PReturnAll", SMA_EM_GetData($data, 52, 56, 1)+0/10);
		readingsEndUpdate($hash, 1);
	}
	$socket->mcast_drop('239.12.255.254');
	
	
	
}

sub SMA_EM_GetData() {
	my($data, $startByte, $endByte, $debug)=@_;
	my $return;
	my $byte;
	for($byte=0; $byte<length($data); $byte=$byte+1) {
		if($byte >= $startByte-1 && $byte <=  $endByte-1) {
			if($debug == 1) {
				Log3 "SMA", 5, "SMA_GetData: byte: ".$byte.": ".sprintf("%02lx", ord substr($data, $byte, 1));
			}
			$return = $return.sprintf("%02lx", ord substr($data, $byte, 1));
		}
	}
	Log3 'ABC', 5, hex($return);
	return(hex($return));
}


1;