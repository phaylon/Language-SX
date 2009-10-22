#!/usr/bin/env perl
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

throws_ok { sx_read '(foo}' } E_SYNTAX, 'wrong cell closer exception';
like $@, qr/expected cell to be closed/i, 'correct error message';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 5, 'correct char number';

throws_ok { sx_read '(foo' } E_SYNTAX, 'unclosed cell exception';
like $@, qr/unexpected end of stream/i, 'correct error message';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 1, 'correct char number';

done_testing;
