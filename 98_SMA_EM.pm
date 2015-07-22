## ##############################################################################
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
	my $i=0;
	$socket = IO::Socket::Multicast->new(LocalPort=>9522);
	$socket->mcast_add('239.12.255.254');
#	while($i<=10) {
		#listen at multicast port
	
		$socket->recv($data, 600);
	
		readingsBeginUpdate($hash);
		my $serialNumber = SMA_EM_GetData($data, 21, 24, 0, 0);
		readingsBulkUpdate($hash, "PConsumptionAll", SMA_EM_GetData($data, 32, 35, 10, 1));
		readingsBulkUpdate($hash, "PReturnAll", SMA_EM_GetData($data, 52, 55, 10, 1));
		readingsBulkUpdate($hash, "QAll", SMA_EM_GetData($data, 92, 95, 10, 1));
		readingsBulkUpdate($hash, "SBezugAll", SMA_EM_GetData($data, 112, 115, 10, 1));
		readingsBulkUpdate($hash, "SEinspeisungAll", SMA_EM_GetData($data, 132, 135, 10, 1));
		readingsBulkUpdate($hash, "cos phiAll", SMA_EM_GetData($data, 152, 155, 1000, 1));

                readingsBulkUpdate($hash, "PConsumptionL1", SMA_EM_GetData($data, 160, 163, 10, 1));
                readingsBulkUpdate($hash, "PReturnL1", SMA_EM_GetData($data, 180, 183, 10, 1));
                readingsBulkUpdate($hash, "QL1", SMA_EM_GetData($data, 220, 223, 10, 1));
                readingsBulkUpdate($hash, "SBezugL1", SMA_EM_GetData($data, 240, 243, 10, 1));
                readingsBulkUpdate($hash, "SEinspeisungL1", SMA_EM_GetData($data, 260, 263, 10, 1));
                readingsBulkUpdate($hash, "THDL1", SMA_EM_GetData($data, 280, 283, 1000, 1));
                readingsBulkUpdate($hash, "UL1", SMA_EM_GetData($data, 288, 291, 1000, 1));
                readingsBulkUpdate($hash, "cosPhiL1", SMA_EM_GetData($data, 296, 299, 1000, 1));

                readingsBulkUpdate($hash, "PBezugL2", SMA_EM_GetData($data, 304, 307, 10, 1));
		readingsBulkUpdate($hash, "PReturnL2", SMA_EM_GetData($data, 324, 327, 10, 1));
                readingsBulkUpdate($hash, "QL2", SMA_EM_GetData($data, 364, 367, 10, 1));
                readingsBulkUpdate($hash, "SBezugL2", SMA_EM_GetData($data, 384, 387, 10, 1));
                readingsBulkUpdate($hash, "SEinspeisungL2", SMA_EM_GetData($data, 404, 407, 10, 1));
                readingsBulkUpdate($hash, "THDL2", SMA_EM_GetData($data, 424, 427, 1000, 1));
                readingsBulkUpdate($hash, "UL2", SMA_EM_GetData($data, 432, 435, 1000, 1));
                readingsBulkUpdate($hash, "cosPhiL2", SMA_EM_GetData($data, 440, 443, 1000, 1));

		readingsBulkUpdate($hash, "PBezugL3", SMA_EM_GetData($data, 448, 451, 10, 1));
                readingsBulkUpdate($hash, "PReturnL3", SMA_EM_GetData($data, 468, 471, 10, 1));
                readingsBulkUpdate($hash, "QL3", SMA_EM_GetData($data, 508, 511, 10, 1));
                readingsBulkUpdate($hash, "SBezugL3", SMA_EM_GetData($data, 528, 531, 10, 1));
                readingsBulkUpdate($hash, "SEinspeisungL3", SMA_EM_GetData($data, 548, 551, 10, 1));
                readingsBulkUpdate($hash, "THDL3", SMA_EM_GetData($data, 568, 571, 1000, 1));
                readingsBulkUpdate($hash, "UL3", SMA_EM_GetData($data, 576, 579, 1000, 1));
                readingsBulkUpdate($hash, "cosPhiL3", SMA_EM_GetData($data, 584, 587, 1000, 1));

		readingsEndUpdate($hash, 1);
		$i = $i+1;
#	}
	$socket->mcast_drop('239.12.255.254');
	
	
	
}

sub SMA_EM_GetData() {
	my($data, $startByte, $endByte, $divider, $debug)=@_;
	my $return;
	my $byte;
	for($byte=0; $byte<length($data); $byte=$byte+1) {
		if($byte >= $startByte && $byte <=  $endByte) {
			if($debug == 1) {
				Log3 "SMA", 5, "SMA_GetData: byte: ".$byte.": ".sprintf("%02lx", ord substr($data, $byte, 1));
			}
			$return = $return.sprintf("%02lx", ord substr($data, $byte, 1));
		}
	}
	if($divider != 0) {
		$return = (hex($return)+0)/$divider;
	} else {
		$return = hex($return);
	}
	if($debug == 1) {
		Log3 "SMA", 5, $return;
	}
	return($return);
}


1;
