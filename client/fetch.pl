#!/usr/bin/perl
#
# example client for Db_proxy.pm
# Alexander Kuehn <alexander.kuehn@hp.com>
# Example:
#    fetch.pl [configfile] "select colA, colB from table;" | sed -n '1!p'
# the first line will be the column names which can filtered
# using sed as shown above
# It's also possible to specify several queries at once.
# The output will be appended in that case.
#
use strict;
use English;
use Db_proxy;
sub trim;

my $SCRIPT_NAME = $0;
# change currentdir to our dir so we can open the config
if ($0=~ /.+\//) {
	$SCRIPT_NAME = $POSTMATCH;
	chdir $MATCH if defined $MATCH;
}

local $::cfgfile = "db_proxy.cfg";	# default config file 
if ( defined $ARGV[0] && -r $ARGV[0] ) {
	$::cfgfile=shift @ARGV;		# if first arg is readable file assume its a configfile
}
local $::config;

open (CFGFILE, $::cfgfile) or die ("Could not open $::cfgfile $!\n");
while (<CFGFILE>) {
	if ($_ =~ /^\s*\w+\s*=.+$/) {
		my ($key, $val)="";
		($key, $val) = split (/=/, $_, 2);
		trim($key, $val);
		chop( $val= eval "<<__EOD__\n$val\n__EOD__");	#expand variables
		if($key =~ /^ENV_/){
			$ENV{$POSTMATCH} = $val;
		} else {
			$::config{$key} = $val;
		}
	}
}
close CFGFILE;
if(defined $::config{"url"}) {
	$::config{"compression"}=(defined $::config{"compression"}) ? $::config{"compression"} : 0 ;
	my $db;
	if(defined $::config{"auth_realm"}) {
		$db = Db_proxy->new({ "url" => $::config{"url"}, "compression" => $::config{"compression"},
		 "auth_realm" => $::config{"auth_realm"}, "auth_user" => $::config{"auth_user"}, 
		 "auth_pass" => $::config{"auth_pass"} });
	} else {
		$db = Db_proxy->new({ url => $::config{"url"}, compression => $::config{"compression"} });
	}
	if($db) {
		for (@ARGV) {
			my @res;
			my $res = $db->NewFetchTab($_, \@res);
			if ($res){
				for (my $cnt=0;$cnt<=$#res;$cnt++) {
					print join("\t", map { defined $_ ? $_ : "NULL" } @{$res[$cnt]}) . "\n";
				}
			}
		}
	}
} else {
	print "No url defined in $::cfgfile. :(\n";
}

exit(0);

##############################################################################
# function trims all parameters (eliminates whitespaces at beginning/end of strings)
# parameters: strings to be trimmed
# return: nothing - changes are made directly
##############################################################################
sub trim {
	for (@_) {
		if (defined $_){
			s/^\s+//;
			s/\s+$//;
		}
	}
}
