#!/usr/bin/env perl
use Template::SX::Constants qw( :all );
use Template::SX::Test      qw( :all );
use Test::Most;

my @vars = (
    [['x', { x => 23 }],                    23,     'passed variable'],
    [['+', { '+' => 23 }],                  23,     'non-alpha variable'],
    [['*foo/bar*', { '*foo/bar*', 23 }],    23,     'complex variable'],
    [['λ', { 'λ', 23 }],                    23,     'lambda named variable'],
);

is_result @$_ 
    for @vars;

throws_ok { sx_run 'foobar' } E_UNBOUND, 'unbound variable exception';
like $@, qr/unbound variable/i, 'correct error message';
like $@, qr/foobar/, 'correct variable name in error message';
is $@->variable_name, 'foobar', 'correct variable name in exception';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 1, 'correct char number';

done_testing;

