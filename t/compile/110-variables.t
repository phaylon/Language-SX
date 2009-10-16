#!/usr/bin/env perl
use Template::SX::Test qw( :all );
use Test::More;

my @vars = (
    [['x', { x => 23 }],                    23,     'passed variable'],
    [['+', { '+' => 23 }],                  23,     'non-alpha variable'],
    [['*foo/bar*', { '*foo/bar*', 23 }],    23,     'complex variable'],
    [['λ', { 'λ', 23 }],                    23,     'lambda named variable'],
);

is_result @$_ 
    for @vars;

done_testing;

