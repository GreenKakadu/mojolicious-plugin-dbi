package Mojolicious::Plugin::Dbi;
use strict;
use warnings;
use base 'Mojolicious::Plugin';
use DBI;

our $VERSION = '0.01';

sub register {
	my ( $self, $app, $args ) = @_;
	$args ||= {};
	my $stash_key = $args->{stash_key} || 'dbh';
	my $ext_dbh = $args->{dbh} if $args->{dbh};
	$app->plugins->add_hook(
		before_dispatch => sub {
			my ( $self, $c ) = @_;
			my $dbh;
			if ( $args->{dbh} ) {

				#external dbh
				$dbh = $args->{dbh};
			}
			else {

				#make new connection
				$c->app->log->debug("start connect to DB $args->{dsn}");
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

			}
			$c->stash( $stash_key => $dbh );

		}
	);

	unless ( $args->{no_disconnect} ) {
		$app->plugins->add_hook(
			after_dispatch => sub {
				my ( $self, $c ) = @_;
				if ( $c->stash('dbh') ) {
					$c->stash('dbh')->disconnect
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
 
version 0.01
 
=head1 SYNOPSIS

	 app->plugin('dbi',{'dsn' => 'dbi:SQLite:dbname=data/sqlite.db',
	 					'username' => 'cheburashka',
	 					'password' => 'Pioneer1966',
	 					'no_disconnect' => 1,
	 					'stash_key' => 'dbh',
	 					'dbi_attr' => { 'AutoCommit' => 1, 'RaiseError' => 1, 'PrintError' =>1 }
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

 
=head2 C<stash_key>
 
    L<DBI> database handle object will be saved in stash using this key, default value 'dbh'
    
    
=head1 SEE ALSO
 
L<DBI>
 
L<Mojolicious>  

=head2 TODO

Tests  

=head1 AUTHOR
 
Konstantin Kapitanov, C<< <perlovik at gmail.com> >> 
 
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2009 Konstantin Kapitanov, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
