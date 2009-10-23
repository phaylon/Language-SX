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
);

my @fails = (
    ['(apply)',             [E_PARAMETER,   qr/argument/],      'apply without any arguments'],
    ['(apply +)',           [E_PARAMETER,   qr/argument/],      'apply with missing arguments'],
    ['(apply + 3 4)',       [E_PARAMETER,   qr/list/],          'apply with non-list as last argument'],
    ['(apply 3 `())',       [E_TYPE,        qr/applicant/],     'apply with invalid applicant'],
);

with_libs(sub {

    is_result @$_ for @try;
    is_error  @$_ for @fails;

}, qw( Data::Numbers Data::Functions Quoting ));

done_testing;
