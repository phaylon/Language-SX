#!/usr/bin/env perl
use strict;
use warnings;
use MooseX::Declare;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

my @should_work = (

    ['(+)',             0,          'addition without arguments'],
    ['(+ 3)',           3,          'addition with single argument'],
    ['(+ 2 3)',         5,          'addition with multiple arguments'],
    ['(+ 2 3 4 5)',     14,         'addition with many arguments'],

    ['(-)',             0,          'subtraction without arguments'],
    ['(- 3)',           3,          'subtraction with single argument'],
    ['(- 9 5)',         4,          'subtraction with multiple arguments'],
    ['(- 10 2 1 3)',    4,          'subtraction with many arguments'],

    ['(*)',             0,          'multiplication without arguments'],
    ['(* 3)',           3,          'multiplication with single argument'],
    ['(* 3 4)',         12,         'multiplication with multiple arguments'],
    ['(* 5 4 3 2)',     120,        'multiplication with many arguments'],

    ['(/)',             0,          'division without arguments'],
    ['(/ 3)',           3,          'division with single argument'],
    ['(/ 8 2)',         4,          'division with multiple arguments'],
    ['(/ 360 12 2 5)',  3,          'divisoin with many arguments'],

    ['(<=> 2 1)',       1,          'compare with first argument bigger'],
    ['(<=> 1 2)',       -1,         'compare with second argument bigger'],
    ['(<=> 2 2)',       0,          'compare with equal numbers'],
);

my @should_fail = (

    ['(/ 3 0)',         [E_CAPTURED,    qr/zero/],          'division by zero'],
    ['(<=>)',           [E_PARAMETER,   qr/argument/],      'compare without arguments'],
    ['(<=> 3)',         [E_PARAMETER,   qr/argument/],      'compare with single argument'],
    ['(<=> 3 4 5)',     [E_PARAMETER,   qr/argument/],      'compare with too many arguments'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, qw( Data::Numbers ));

done_testing;
