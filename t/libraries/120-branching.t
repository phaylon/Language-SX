#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Constants qw( :all );
use Template::SX::Test      qw( :all );
use Test::Most;

my @try = (
    ['(if 0 2 3)',      3,          'if with false and alternative'],
    ['(if 0 2)',        undef,      'if with false and no alternative'],
    ['(if 1 2 3)',      2,          'if with true and alternative'],
    ['(if 1 2)',        2,          'if with true and no alternative'],
);

with_libs(sub {

    is_result @$_ for @try;

    for my $wrong_args ('(if)', '(if 1)', '(if 1 2 3 4)') {
        throws_ok { sx_run $wrong_args } E_SYNTAX, "exception for $wrong_args";
        like $@, qr/if condition/, 'correct error message';
    }

}, 'Branching');

done_testing;


