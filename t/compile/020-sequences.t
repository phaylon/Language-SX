#!/usr/bin/env perl
use Template::SX::Test qw( :all );
use Test::More;

my @seq = (
    ['2 3', 3, 'top level constant sequence'],
);

is_result @$_ 
    for @seq;

done_testing;

