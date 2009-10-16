#!/usr/bin/env perl
use Template::SX::Test qw( :all );
use Test::More;

my @constants = (
    ['23',      23,     'integer constant'],
    ['0',       0,      'zero constant'],
    ['20_000',  20000,  'underline separated integer constant'],
    ['1_2' ,    12,     'minimal underline separated integer constant'],
    ['0.5',     0.5,    'floating point constant'],
    ['-23',     -23,    'negative integer constant'],
    ['-1.5',    -1.5,   'negative floating constant'],
);

is_result @$_ 
    for @constants;

done_testing;
