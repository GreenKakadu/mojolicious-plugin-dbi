#!perl -T

use Test::More tests => 2;


BEGIN {
	use_ok( 'Mojolicious::Plugin::Dbi' );
}

diag( "Testing Mojolicious::Plugin::Dbi $Mojolicious::Plugin::Dbi::VERSION, Perl $], $^X" );

my $t = Mojolicious::Plugin::Dbi->new();
ok($t && ref($t) eq 'Mojolicious::Plugin::Dbi', 'ok use new')