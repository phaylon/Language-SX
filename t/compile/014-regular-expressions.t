#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

do {
    my $rx = sx_run('rx/foo/');
    is ref($rx), 'Regexp', 'regular expression was parsed';
    ok 'foo' =~ $rx, 'regular expression matches correctly';
    ok not('bar' =~ $rx), 'regular expression does not match when required';
};

do {
    my $rx = sx_run('rx( \A [a-z] - [0-9] \) $foo )i');
    is ref($rx), 'Regexp', 'complex regular expression was parsed';
    ok 'F-3)$fOo' =~ $rx, 'complex regular expression matches';
};

do {
    my $rx = sx_run('rx{ a b \} c }-x');
    is ref($rx), 'Regexp', 'regular expression with removed flag was parsed';
    ok ' a b } c ' =~ $rx, 'removed flag worked';
};

do {
    my $rx = sx_run(q(
        rx(
            \A
            $"
            [a-z]+
            "
            \Z
        )i
    ));
    is ref($rx), 'Regexp', 'multiline regular expression was parsed';
    ok '$"Foo"' =~ $rx, 'multiline regular expression matches';
};

throws_ok { sx_load 'rx/foo/y' } E_SYNTAX, 'invalid modifier raises syntax error';
like $@, qr/modifier 'y'/, 'correct error message';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 1, 'correct char number';

done_testing;
