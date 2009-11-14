#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Test qw( :all );
use Test::Most;

my @constants = (
    ['23',      23,         'integer constant'],
    ['0',       0,          'zero constant'],
    ['20_000',  20000,      'underline separated integer constant'],
    ['1_2' ,    12,         'minimal underline separated integer constant'],
    ['0.5',     0.5,        'floating point constant'],
    ['-23',     -23,        'negative integer constant'],
    ['-1.5',    -1.5,       'negative floating constant'],

    ['#t',      1,          '#t'],
    ['#f',      undef,      '#f'],
    ['#true',   1,          '#true'],
    ['#false',  undef,      '#false'],
    ['#yes',    1,          '#yes'],
    ['#no',     undef,      '#no'],

    [':foo',    'foo',      'keyword with prefix double-colon'],
    ['bar:',    'bar',      'keyword with postfix double-colon'],
    [':x-y-z',  'x_y_z',    'dashes in keywords'],
    [':x23',    'x23',      'numbers in keywords'],

    ['`x::y',   bareword('x::y'),   'bareword with colons'],
);

with_libs(sub {
    is_result @$_ 
        for @constants;
}, 'Quoting');

done_testing;
