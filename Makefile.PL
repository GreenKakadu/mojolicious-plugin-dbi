
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Mojolicious-Plugin-Dbi',
  NAME      => 'Mojolicious::Plugin::Dbi',
  AUTHOR    => "Konstantin\ Kapitanov\ \<perlovik\@gmail\.com\>",
  ABSTRACT  => "simple\ DBI\ plugin\ for\ Mojolicious\.",
  VERSION   => '0.01',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Mojo" => '0.999910',
    "DBI" => '0',
  },
  test => {TESTS => 't/*.t'}
);

