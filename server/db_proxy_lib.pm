#
# db proxy - the server portion to Db_proxy(3pm)
# provides access to a DBI datasource via plain HTTP(S)
# including gzip encoding support
# Author: Alexander Kuehn <alexander.kuehn@hp.com>
# 
#
package db_proxy_lib;
$db_proxy_lib'version = "1.0";

use strict;
use English;
use YAML qw(freeze);
# main config file almost completely editable on admin space
local $::cfgfile = "/opt/webhost/whapp1/shared/apache/db/db_proxy.cfg";

sub trim;
sub readConfigFile;
#local $::True=1;
local $::False=0;

##############################################################################
# return the string if it's defined and '' otherwise
##############################################################################
sub SafeString ($) {
	return (defined ${$_[0]}) ? ${$_[0]} : "";
}

##############################################################################
# print messages to the httpd error log
# parameters: text for output
##############################################################################
sub errlog ($) {
	if (SafeString(\$_[0]) ne "") {
		if ( $::config{debug} == 1) {
			use POSIX qw(strftime);
			my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
			open (DEBUG, ">> /opt/webhost/whapp1/apache/logs/db_proxy-$::config{dbuser}.log") or die "Error while errlog - $!";
			print DEBUG "[$now_string] $_[0]\n";
			close DEBUG;
		}
	}
}

#############################################################################
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

##############################################################################
# function reads values of config file and stores them in %config
# parameters: nothing
# return: nothing
##############################################################################
sub readConfigFile {
	open (CFGFILE, $::cfgfile) or cgiDie ("Could not open $::cfgfile $!\n");
	while (<CFGFILE>) {
		if ($_ =~ /^\s*\w+\s*=.+$/) {
			my ($key, $val)="";
			($key, $val) = split (/=/, $_, 2);
			trim($key, $val);
			$val =~ s/#IP#/$ENV{SERVER_ADDR}/g if (defined $ENV{SERVER_ADDR});
			$::config{$key} = $val;
		}
	}
	close CFGFILE;
	# set browser var
}

###################################################
# execSQL                                         #
# executes all parameters as SQL-querie           #
###################################################
sub execSQL {
	my $rows = 0;
	for (@_) {
		errlog ("SQL: $_\n");
		my $sth = $::dbh->prepare($_);
		my $rc = $sth->execute;
		errlog("SQL-return: $rc\n");
		my $rcf = $sth->finish;
		$rows += $sth->rows;
	}
	return $rows;
}

##############################################################################
# function read queries from $::in{q} and return results
# parameters: nothing
# return: nothing
##############################################################################
sub st_do() {
	my @q=split("\0", $::in{"q"});
	my @res;
	for (@q) {
#		$DBI::errstr=undef;
		my $t=execSQL($_);
		if(defined $DBI::errstr) {
			push @res,$DBI::errstr;
			$DBI::errstr=undef;
		} else {
			push @res,$t;
		}
	}
	print freeze \@res;
}

###############################################################################
# FetchTable(select statement,reference to hash of arrays)
# executes the given select statement and fetches the result
# into the given hash of arrays
# returns the number of rows affected
# Example:
#			my %evttable=();
#			FetchTable("select * FROM EVENTS;",\%evttable);
###############################################################################
# FetchTable
############################################################################## 
sub FetchTable($;\%) {
	return 0 if ($_[0] eq "");
	errlog ("SQL: $_[0]");
	my $q=shift;
	my $hash_ref=shift; 
	my $sth = $::dbh->prepare($q);
	my $rc = $sth->execute;
	if ( $rc ) {
		my $numRows = 0;
		if ($sth->{'NUM_OF_FIELDS'}) {
			my @cols=@{$sth->{'NAME'}};
			while (my $rowref = $sth->fetchrow_arrayref()) { 
				$numRows++;
				my $i=0;
				for(@cols) {
					push(@{$$hash_ref{$_}}, $$rowref[$i++]);
				}
			}
			unless ($numRows) {
				for(@cols) {
					$$hash_ref{$_}=undef;
				}
			}
		}
		my $rcf = $sth->finish;
		return $numRows;
	}
	else {
		errlog("Fetch failed!");
		return $::False;
	}
}

##############################################################################
# function read queries from $::in{q} and return results
# parameters: nothing
# return: nothing
##############################################################################
sub st_fetchtab() {
	my %res;
	FetchTable($::in{"q"}, %res);
	print freeze \%res;
}

###############################################################################
# st_newfetchtab  , return array of arrays, first subarray are the column names
############################################################################## 
sub st_newfetchtab() {
	errlog ("SQL: " . $::in{"q"} . "\n");
	my $sth = $::dbh->prepare($::in{"q"});
	my $rc = $sth->execute;
	if ( $rc ) {
		my @headers=@{$sth->{'NAME'}};
		my $ary_ref=$sth->fetchall_arrayref;
		unshift (@{$ary_ref}, [@headers]);
		print freeze $ary_ref;
	} else {
		errlog("execute failed!");
		return undef;
	}
}
############################################################################## 
sub cgiDie {
	my $val = shift @_;
	print "<h2>CGI-Error: $val</h2>\n";
	print "Config:<br>\n", map { "$_ = $::config{$_} <br>\n" } keys %::config if ($::config{debug});
	print "Values:<br>\n", map { "$_ = $::in{$_} <br>\n" } keys %::in if ($::config{debug});
	print "Values:<br>\n", map { "$_ = $ENV{$_} <br>\n" } keys %ENV if ($::config{debug});
	if(defined $val) {
		die ($val);
	} else {
		die("undefined");
	}
}

1; #return true 
 
