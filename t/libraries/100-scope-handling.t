#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Constants qw( :all );
use Template::SX::Test      qw( :all );
use Test::Most;

my @try = (
    ['(define foo 23) (define bar 42) (+ foo bar)',     65,     'succeeding definitions'],
    ['(define foo) foo',                                undef,  'definition without value'],

    ['((lambda (x y) (+ x y)) 3 4)',                    7,      'lambda generation and application'],
    ['((lambda args args) 1 2)',                        [1, 2], 'lambda generation with all argument capture'],
    ['((lambda (x . ls) ls) 1 2 3)',                    [2, 3], 'lambda generation with rest capture'],
);

push @try, [q{

    (define kons (lambda (n m) (lambda (a) (a n m))))
    (define kar  (lambda (k) (k (lambda (n m) n))))
    (kar (kons 5 6))

}, 5, 'kar/kdr example'];

with_libs(sub {

    is_result @$_ for @try;

    for my $wrong_arg_count ('(lambda)', '(lambda (x))') {

        throws_ok { sx_load $wrong_arg_count } E_SYNTAX, 'lambda with missing arguments raises syntax exception';
        like $@, qr/lambda.*arguments/, 'correct error message';
        is $@->location->{line}, 1, 'correct line number';
        is $@->location->{char}, 1, 'correct char number';
    }

    throws_ok { sx_load '(lambda 23 7)' } E_SYNTAX, 'invalid lambda parameter specification';
    like $@, qr/lambda.*parameter/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 9, 'correct char number';


    throws_ok { sx_load '(lambda (foo 23) 7)' } E_SYNTAX, 'invalid item in lambda parameter list';
    like $@, qr/lambda.*parameter list/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 14, 'correct char number';

    throws_ok { sx_load '(lambda (foo . 23) 7)' } E_SYNTAX, 'invalid item in lambda parameter list rest position';
    like $@, qr/lambda.*parameter list/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 16, 'correct char number';


    throws_ok { sx_load '(lambda (foo . bar . baz) 7)' } E_SYNTAX, 'multiple dots in lambda parameter list';
    like $@, qr/dot/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 20, 'correct char number';

    throws_ok { sx_load '(lambda (foo . bar baz) 7)' } E_SYNTAX, 'multiple rest variables for lambda';
    like $@, qr/rest/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 20, 'correct char number';

    throws_ok { sx_load '(lambda (foo . ) 7)' } E_SYNTAX, 'missing rest variables for lambda';
    like $@, qr/rest/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 14, 'correct char number';


    throws_ok { sx_load '(lambda (foo lambda bar) 7)' } E_RESERVED, 'reserved variable identifier in lambda';
    like $@, qr/reserved/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 14, 'correct char number';


    throws_ok { sx_load '(define lambda)' } E_RESERVED, 'reserved variable definition';
    like $@, qr/reserved/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 9, 'correct char number';

    throws_ok { sx_load '(define lambda 23)' } E_RESERVED, 'reserved variable definition with value';
    like $@, qr/reserved/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 9, 'correct char number';


    for my $invalid_define ('(define)', '(define foo 23 8)', '(define 23 8)', '(define 8)') {

        throws_ok { sx_load $invalid_define } E_SYNTAX, 'reserved variable definition with value';
        like $@, qr/invalid/, 'correct error message';
        is $@->location->{line}, 1, 'correct line number';
        is $@->location->{char}, 1, 'correct char number';
    }

}, 'ScopeHandling', 'Math');

done_testing;


