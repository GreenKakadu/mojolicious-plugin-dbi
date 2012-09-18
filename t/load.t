#!perl -T

use Test::More tests => 2;


BEGIN {
	use_ok( 'Mojolicious::Plugin::DBI' );
}

diag( "Testing Mojolicious::Plugin::DBI $Mojolicious::Plugin::DBI::VERSION, Perl $], $^X" );

my $t = Mojolicious::Plugin::DBI->new();
ok($t && ref($t) eq 'Mojolicious::Plugin::DBI', 'ok use new')
