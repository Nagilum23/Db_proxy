package Db_proxy;

use 5.006;
use strict;
use warnings;
use Carp;

use YAML qw(thaw);
require HTTP::Request;
require LWP::UserAgent;
require LWP::ConnCache;
require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Db_proxy ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.08';

sub new {
    my ( $class, $args ) = @_;
    $class = bless({}, $class);
	croak "Argument to new() must be a HASHREF" if ref $args ne 'HASH';
	for my $arg (qw( url )) {			# verify mandatory args
		if (exists $args->{$arg}) {
			$class->{$arg} = $args->{$arg};
        } else {
			croak "'$arg' argument required" if !exists $args->{$arg};
        }
	}
	my %defaults=( "compression"	=>	0,
					"auth_realm"	=>	"",
					"auth_user"		=>	"",
					"auth_pass"		=>	"");
	for my $arg (keys %defaults) {			# verify optional args
		if (exists $args->{$arg}) {
			$class->{$arg} = $args->{$arg};
        } else {
			$class->{$arg} = $defaults{$arg};
        }
	}
	$class->{'ua'} = LWP::UserAgent->new;
	$class->{'ua'}->env_proxy;
	$class->{'ua'}->timeout(15);
	$class->{'ua'}->conn_cache(LWP::ConnCache->new());
	if ($class->{'compression'}) {
		$class->{'ua'}->default_header("Accept-Encoding" => "gzip, deflate");
	}
	if ($class->{'auth_user'}) {
		my @t=split("/", $class->{'url'});
		unless($t[2] =~ /:\d+$/){		# unless a port is already given
			if($t[0] eq "https:"){
				$t[2].=":443";
			} else {
				$t[2].=":80";
			}
		}
		$class->{'ua'}->credentials($t[2], $class->{'auth_realm'}, 
			$class->{'auth_user'}, $class->{'auth_pass'});
	}
	# open & test the connection to workaround
	# https://issues.apache.org/bugzilla/show_bug.cgi?id=12355
	my $res = $class->{'ua'}->post($class->{'url'}, ['s' => 'ft', 'q' => 'select 1;']);
	if ($res->is_success) {
		return $class;
	} else {
		print STDERR $res->message;
		return undef;
	}
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Db_proxy - Perl extension for acessing a database via a HTTP(S) tunnel

=head1 SYNOPSIS

  use Db_proxy;
  my $db = Db_proxy->new( { url => 'https://foo.bar/cgi-bin/db_proxy.pl', compression => 1 } );
  my %res;
  my $res = $db->FetchTable("select * from table;", \%res);
  $db->do("delete from table where col like '';");


=head1 DESCRIPTION

This is a little wrapper library to access a centrally accessible database
through simple HTTP requests.
You need to install and configure the server before you can use this.
This has been tested with SQLite.

=head2 PARAMETERS

Mandatory:
 url	an URL as understood by HTTP::Request pointing to the db_proxy server

Optional:
 compression	gzip encoding, 1 = enable, 0 = disable, default = 0
 auth_realm		when using basic auth this is the real to authenticate against
 auth_user		the username to use for basic auth
 auth_pass		the password to use for basic auth

=head1 SEE ALSO

DBI(3pm), LWP(3pm), HTTP::Request(3pm), Crypt::SSLeay(3pm), Net::SSLeay(3pm)

=head1 AUTHOR

Alexander Kuehn, E<lt>nagilum@nagilum.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alexander Kuehn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

sub FetchTable {
	my $self = shift;
	my $q = shift;
	my $hash_ref = shift;
	my $res = $self->{'ua'}->post($self->{'url'}, ['s' => 'ft', 'q' => $q]);
	if ($res->is_success) {
		%{$hash_ref} = %{ thaw($res->decoded_content) };
	} else {
		$$hash_ref{"message"}=$res->message;
	}
	return $res->is_success;
}

sub do {
	my $self = shift;
	my $q = shift;
	my $ary_ref = shift;
	my $res = $self->{'ua'}->post($self->{'url'}, [ 's' => 'do', 'q' => $q]);
	if ($res->is_success) {
		@{$ary_ref} = @{ thaw($res->decoded_content) };
	} else {
		push @{$ary_ref}, $res->message;
	}
	return $res->is_success;
}

# fetch as a array of arrays
sub NewFetchTab {
	my $self = shift;
	my $q = shift;
	my $ary_ref = shift;
	my $res = $self->{'ua'}->post($self->{'url'}, ['s' => 'fb', 'q' => $q]);
	if ($res->is_success) {
		@{$ary_ref} = @{ thaw($res->decoded_content) };
	} else {
		$$hash_ref{"message"}=$res->message;
	}
	return $res->is_success;
}

