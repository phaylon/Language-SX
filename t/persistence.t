#!/usr/bin/env perl
use strict;
use warnings;
use Language::SX::Constants qw( :all );
use Language::SX::Test      qw( :all );
use Test::Most;
use utf8;

use Language::SX;

my $sx = Language::SX->new;

my @modifiers = (
    '(define (double n) (* n 2))',
    '(define value 23)',
    '(set! value (++ value))',
    '(set! value { value: value })',
    '(set! value { value: (double (at value :value)) })',
    'value',
);

my $expected = { value => 48 };

do {
    my $vars = {};
    my $result;

    $result = $sx->run(string => $_, vars => $vars, persist => 1)
        for @modifiers;

    is_deeply $result, $expected, 'multiple sx runs can persist';
    is_deeply $vars->{value}, $expected, 'variable hash has correct form';
    is ref($vars->{double}), 'CODE', 'declared function is available';
};

do {
    my $vars = {};
    my @docs = map { $sx->read(string => $_) } @modifiers;
    my $result;

    $result = $_->run(vars => $vars, persist => 1)
        for @docs;

    is_deeply $result, $expected, 'multiple sx document runs can persist';
    is_deeply $vars->{value}, $expected, 'variable hash has correct form';
    is ref($vars->{double}), 'CODE', 'declared function is available';
};

done_testing;
