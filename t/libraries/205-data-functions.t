#!/usr/bin/env perl
use strict;
use warnings;
use MooseX::Declare;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

my @try = (
    ['(apply + 1 2 `(3 4))',                10,     'simple function application'],
    ['(apply apply + `(1 2 (3 4)))',        10,     'applying apply to itself'],

    ['(lambda? (-> _))',                    1,      'lambda predicate with single lambda'],
    ['(lambda? (-> _) (-> 3))',             1,      'lambda predicate with multiple lambdas'],
    ['(lambda? (-> _) 23 (-> 4))',          undef,  'lambda predicate with non-lambda argument'],

    ['(<- even? length "abcd")',            1,      'cascading arrow'],
    ['(<- even? length "abc")',             undef,  'cascading arrow with last false'],
    ['(<- 3 #f)',                           undef,  'cascading arrow with skipped'],
    ['(<-)',                                undef,  'cascading arrow without arguments'],
    ['(<- 23)',                             23,     'cascading arrow with single argument'],
);

my @fails = (
    ['(apply)',             [E_PARAMETER,   qr/argument/],      'apply without any arguments'],
    ['(apply +)',           [E_PARAMETER,   qr/argument/],      'apply with missing arguments'],
    ['(apply + 3 4)',       [E_PARAMETER,   qr/list/],          'apply with non-list as last argument'],
    ['(apply 3 `())',       [E_TYPE,        qr/applicant/],     'apply with invalid applicant'],

    ['(lambda?)',           [E_PARAMETER,   qr/at least/],      'lambda predicate without arguments'],

    ['(<- 3 4)',            [E_TYPE,        qr/argument 1/],    'cascading arrow with non-applicant'],
);

with_libs(sub {

    is_result @$_ for @try;
    is_error  @$_ for @fails;

}, qw( Data::Numbers Data::Functions Quoting ScopeHandling Data::Common ));

done_testing;
