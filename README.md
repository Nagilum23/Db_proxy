Db_proxy version 1.08
=====================

This module and the included cgi can be used to proxy access to a database
via cgi-bin. This allows (for example) to share a single SQLite database
with multiple hosts.

This archive includes a client libarary used to access the installed
"server". It also includes the server which provides access to the database
to the clients and a sample client.

## INSTALLATION

To install this module type the following:

   perl Makefile.PL [PREFIX=~]
   make
   make test
   make install

You will have to set up the 'server'. The bundled server is simple cgi with a 
plaintext configuration file. It contains no access controls so you will have
to use .htaccess or similar mechanisms to protect your database!
The usual *_proxy environment variables will be honoured.
If you want to access an SSL protected server see Crypt::SSLeay(3pm)
for relevant environment variables to configure things like 
client auth, ca-bundle, etc..

## DEPENDENCIES

This module requires these other modules and libraries:

   * HTTP::Request - http://search.cpan.org/~gaas/HTTP-Message/lib/HTTP/Request.pm
   * YAML - http://search.cpan.org/~mstrout/YAML/lib/YAML.pm

If you want access SSL protected content you'll also need Crypt::SSLeay - http://search.cpan.org/~nanis/Crypt-SSLeay/SSLeay.pm.

## COPYRIGHT AND LICENCE

Copyright (C) 2010-2013 by Alexander Kuehn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


