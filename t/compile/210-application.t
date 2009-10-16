#!/usr/bin/env perl
use Template::SX::Test qw( :all );
use Test::More;

my $vars = { 
    add     => sub { $_[0] + $_[1] },
    kons    => sub { my ($x, $y) = @_; sub { $_[0]->($x, $y) } },
    kar     => sub { $_[0]->(sub { $_[0] }) },
    kdr     => sub { $_[0]->(sub { $_[1] }) },
};

my @apply = (
    [['(add 2 3)', $vars],          5,          'simple function application'],
    [['(kar (kons 2 3))', $vars],   2,          'kons/kar example'],
    [['(kdr (kons 2 3))', $vars],   3,          'kons/kdr example'],
);

is_result @$_ 
    for @apply;

done_testing;

