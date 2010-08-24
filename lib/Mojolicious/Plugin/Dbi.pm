package Mojolicious::Plugin::Dbi;
use strict;
use warnings;
use base 'Mojolicious::Plugin';
use DBI;

our $VERSION = '0.02';

sub register {
	my ( $self, $app, $args ) = @_;
	$args ||= {};
	my $stash_key = $args->{stash_key} || 'dbh';
	my $ext_dbh = $args->{dbh} if $args->{dbh};
	
	$app->log->debug("register Mojolicious::Plugin::Dbi dsn: $args->{dsn}");
	unless (ref($app)->can('_dbh'))
	{
		ref($app)->attr('_dbh');
		ref($app)->attr('_dbh_requests_counter'=>0);
	}
	
	my $max_requests_per_connection = $args->{requests_per_connection}||100;
	$app->plugins->add_hook(
		before_dispatch => sub {
			my ( $self, $c ) = @_;
			my $dbh;
			if ( $args->{dbh} ) {

				#external dbh
				$dbh = $args->{dbh};
			}
			elsif ($c->app->_dbh and $c->app->_dbh_requests_counter < $max_requests_per_connection)
			{
				$dbh =$c->app->_dbh;
				$c->app->log->debug("use cached DB connection, requests served: ".$c->app->_dbh_requests_counter);
				$c->app->_dbh_requests_counter($c->app->_dbh_requests_counter + 1);
			}
			
			else {

				#make new connection
				$c->app->log->debug("start new DB connection to DB $args->{dsn}");
				$dbh = DBI->connect(
					$args->{dsn},
					$args->{username} || '',
					$args->{password} || '',
					$args->{dbi_attr} || {}
				);
				unless ($dbh) {
					my $err_msg = "DB connect error. dsn=$args->{dsn}, error: $DBI::errstr";
					$c->app->log->error($err_msg);

					# Render exception template
					my $options = {
						template  => 'exception',
						format    => 'html',
						status    => 500,
						exception => $err_msg
					};
					$c->app->static->serve_500($c);
					return;
				}

				if ( $args->{'on_connect_do'} ) {
					if (    ref( $args->{'on_connect_do'} )
						and ref( $args->{'on_connect_do'} ) ne 'ARRAY' )
					{
						$c->app->log->error('DB connect error on_connect_do param is not arrayref or scalar');
					}
					else {
						eval {
							if ( !ref( $args->{'on_connect_do'} ) )
							{
								$dbh->do( $args->{'on_connect_do'} );
							}
							else {
								foreach
								  my $do_cmd ( @{ $args->{'on_connect_do'} } )
								{
									$dbh->do($do_cmd);
								}
							}
						};
						if ($@) {
							$c->app->log->error(
								"DB on_connect_do error $@ " . $dbh->errstr );
							$c->app->static->serve_500($c);
							return;
						}
					}
				}
				
				$c->app->_dbh($dbh);
				$c->app->_dbh_requests_counter(1);

			}

			$c->stash( $stash_key => $dbh );
			

		}
	);

	unless ( $args->{no_disconnect} ) {
		$app->plugins->add_hook(
			after_dispatch => sub {
				my ( $self, $c ) = @_;
				$c->app->_dbh(0);
				$c->app->_dbh_requests_counter(0);	
				if ( $c->stash($stash_key) ) {
							
					$c->stash($stash_key)->disconnect
					  or $c->app->log->error("Disconnect error $DBI::errstr");
				}
				$c->app->log->debug("disconnect from DB $args->{dsn}");
			}
		);
	}
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Dbi - simple DBI plugin for Mojolicious.

=head1 DESCRIPTION
 
L<Mojolicious::Plugin::Dbi> is a simple DBI plugin for L<Mojolicious>. It connects to database and 
creates L<DBI> database handle object  with provided parameters.
L<DBI> database handle object  is placed in the stash.
 
=head1 VERSION
 
version 0.02
 
=head1 SYNOPSIS

	 app->plugin('dbi',{'dsn' => 'dbi:SQLite:dbname=data/sqlite.db',
	 					'username' => 'cheburashka',
	 					'password' => 'Pioneer1966',
	 					'no_disconnect' => 1,
	 					'stash_key' => 'dbh',
	 					'dbi_attr' => { 'AutoCommit' => 1, 'RaiseError' => 1, 'PrintError' =>1 },
	 					'on_connect_do' =>[ 'SET NAMES UTF8'],
	 					'requests_per_connection' => 200
	 					});
    
    #and in you app
    my $dbh = $c->stash('dbh');
    $dbh->do('create table ......');

=head1 ATTRIBUTES

=head2 C<dsn> 

The dsn value must begin with "dbi:driver_name:". The driver_name specifies the driver that will be used to make the connection. (Letter case is significant.)
See L<DBI/connect> $data_source description

=head2 C<username>
 
Database user

=head2 C<password>

password for database user

=head2 C<no_disconnect>

If true, than not disconnect from database after dispatching.
Default false.

=head2 C<dbi_attr>

See L<DBI/connect> and L<DBI/ATTRIBUTES COMMON TO ALL HANDLES> for more details


=head2 C<on_connect_do>

Specifies things to do immediately after connecting or re-connecting to the database. Its value may contain:

=item

	C<a scalar> This contains one SQL statement to execute.
	
=item 

	C<an array reference> This contains SQL statements to execute in order. Each element contains a string or a code reference that returns a string. 	

 
=head2 C<stash_key>
 
    L<DBI> database handle object will be saved in stash using this key, default value 'dbh'
    
=head2 C<requests_per_connection>

How much requests served cached persistent connection before reconnect. Default 100

    
=head1 SEE ALSO
 
L<DBI>
 
L<Mojolicious>  

=head2 TODO

Tests  

=head1 AUTHOR
 
Konstantin Kapitanov, C<< <perlovik at gmail.com> >> 
 
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2010 Konstantin Kapitanov, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
