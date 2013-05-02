#!/opt/perl_64/bin/bin/perl -w
#
# db proxy - the server portion to Db_proxy(3pm)
# provides access to a DBI datasource via plain HTTP(S)
# including gzip encoding support
# Author: Alexander Kuehn <alexander.kuehn@hp.com>
# 
#
# add include additional paths

unshift(@INC, '/home/user/public_html/cgi-bin/');

use strict;
use English;
use DBI;
use YAML qw(freeze);
require "cgi_lib.pm";
require "db_proxy_lib.pm";
local $::cfgfile = "/home/user/db/db_proxy.cfg";

#local $::True=1;
local $::False=0;

# hashs for config, input and array for owners
local %::config = ();

local (%::in,		# The form data, should be named %cgi_data
      %::cgi_cfn,   # The uploaded file(s) client-provided name(s)
      %::cgi_ct,    # The uploaded file(s) content-type(s).  These are
					#   set by the user's browser and may be unreliable
      %::cgi_sfn,	# The uploaded file(s) name(s) on the server (this machine)
      $::cgi_ret,	# Return value of the ReadParse call.
     );

local %::states = (
	"do"		=>	\&db_proxy_lib::st_do,
	"ft"		=>	\&db_proxy_lib::st_fetchtab,
	"fb"		=>	\&db_proxy_lib::st_newfetchtab
	);

&db_proxy_lib::readConfigFile;
# When writing files, several options can be set..
# Spool the files to the /tmp directory
$cgi_lib::writefiles = '/tmp';
# Limit upload size to avoid using too much memory
$cgi_lib::maxdata    = 16777216;
# The following lines are solely to suppress 'only used once' warnings
$cgi_lib::writefiles = $cgi_lib::writefiles;
$cgi_lib::maxdata    = $cgi_lib::maxdata;
$::cgi_ret = cgi_lib::ReadParse(\%::in,\%::cgi_cfn,\%::cgi_ct,\%::cgi_sfn);

local $::dbh = DBI->connect($::config{data_source}, $::config{dbuser}, $::config{dbpass});
local $::dberror;	#error string
unless ($::dbh) {
	print "$DBI::err ->\n$DBI::errstr";
	$::dberror=$DBI::errstr;
}
$::dbh->{RaiseError} = 1;
#$::dbh->commit;

#print "Content-Encoding: gzip\n" if ($ENV{"HTTP_ACCEPT_ENCODING"} =~ /gzip/);
print "Expires: -1\n"
	. "Pragma: no-cache\n"
	. "Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0\n";
print "Content-Type: application/x-yaml\n\n"; 

$|= 1; # - necessary for binary outputs
# gzip encoding
# set STDOUT to gzip pipe
#if ($ENV{"HTTP_ACCEPT_ENCODING"} =~ /gzip/) {
#	open (OUTPUT, "|$::config{gzip} -fc") || cgiDie ("Could not open gzip pipe!\n");
#	*STDOUT=*OUTPUT;
#}

if ($::states{$::in{"s"}}) {
	$::states{$::in{"s"}}->();
} else {
	cgiDie ("Invalid arguments!");
}
$::dbh->disconnect;
close OUTPUT;
exit;

 
