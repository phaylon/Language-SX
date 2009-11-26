#!/usr/bin/env perl
use strict;
use warnings;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

throws_ok { sx_load '(foo bar 0baz)' } E_SYNTAX, 'unknown token raises syntax error';
like $@, qr/unable to parse/, 'correct error message';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 10, 'correct char number';

done_testing;
