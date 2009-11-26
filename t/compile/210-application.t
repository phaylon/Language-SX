#!/usr/bin/env perl
use strict;
use warnings;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

my $vars = { 
    add     => sub { $_[0] + $_[1] },
    kons    => sub { my ($x, $y) = @_; sub { $_[0]->($x, $y) } },
    kar     => sub { $_[0]->(sub { $_[0] }) },
    kdr     => sub { $_[0]->(sub { $_[1] }) },
};

my @apply = (
    [['(add 2 3)', $vars],              5,          'simple function application'],
    [['(kar (kons 2 3))', $vars],       2,          'kons/kar example'],
    [['(kdr (kons 2 3))', $vars],       3,          'kons/kdr example'],

    [['((quote foo) :value)', $vars],   'foo',      'object method application'],
);

with_libs(sub {

    is_result @$_ 
        for @apply;

    throws_ok { sx_load '()' } E_SYNTAX, 'empty application error';
    like $@, qr/empty application/i, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 1, 'correct char number';

    throws_ok { sx_run q{`("foo" ,(bar 23))}, { bar => sub { die "PERL ERROR\n" } } } E_CAPTURED, 'application captures error';
    like $@, qr/application/, 'correct error message';
    like $@, qr/PERL ERROR/, 'error message contains application error';
    is $@->captured, "PERL ERROR\n", 'correct captured error';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 10, 'correct char number';

    throws_ok { sx_run q{ (foo 23) }, { foo => {} } } E_TYPE, 'hash application throws exception';
    like $@, qr/invalid applicant/, 'correct error message';
    like $@, qr/HASH/, 'error message contains ref type';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 2, 'correct char number';

    throws_ok { sx_run q{('foo :thismethoddoesnotexist)}, {} } E_APPLY, 'unknown method call raises exception';
    like $@, qr/thismethoddoesnotexist/, 'error message contains method name';
    like $@, qr/Runtime::Bareword/, 'error message contains object class';

}, qw( Quoting ));

done_testing;

