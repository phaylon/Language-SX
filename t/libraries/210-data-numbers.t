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

    ['(== 2 2)',        1,          'equality with two equal arguments'],
    ['(== 4 4 4 4)',    1,          'equality with many equal arguments'],
    ['(== 3 4)',        undef,      'equality with two different arguments'],
    ['(== 3 4 4 3)',    undef,      'equality with mixed arguments'],

    ['(!= 3 4)',        1,          'non-equality with two non-equal arguments'],
    ['(!= 3 4 5 6)',    1,          'non-equality with many non-equal arguments'],
    ['(!= 4 4)',        undef,      'non-equality with two equal arguments'],
    ['(!= 3 7 4 3)',    undef,      'non-equality with mixed arguments'],

    ['(<)',             1,          'less-than without arguments'],
    ['(< 3)',           1,          'less-than with single argument'],
    ['(< 3 4)',         1,          'less-than with multiple arguments in order'],
    ['(< 3 4 5 6)',     1,          'less-than with many arguments in order'],
    ['(< 4 4)',         undef,      'less-than with two equal arguments'],
    ['(< 4 3)',         undef,      'less-than with two arguments out of order'],
    ['(< 2 3 4 4 5)',   undef,      'less-than with all but two items in order'],

    ['(>)',             1,          'more-than without arguments'],
    ['(> 3)',           1,          'more-than with single argument'],
    ['(> 4 3)',         1,          'more-than with multiple arguments in order'],
    ['(> 6 5 4 3)',     1,          'more-than with many arguments in order'],
    ['(> 4 4)',         undef,      'more-than with two equal arguments'],
    ['(> 3 4)',         undef,      'more-than with two arguments out of order'],
    ['(> 6 5 4 4 3)',   undef,      'more-than with all but two items in order'],

    ['(<=)',            1,          'less-than-or-equal without arguments'],
    ['(<= 3)',          1,          'less-than-or-equal with single argument'],
    ['(<= 3 4)',        1,          'less-than-or-equal with multiple arguments in order'],
    ['(<= 3 4 5 6)',    1,          'less-than-or-equal with many arguments in order'],
    ['(<= 4 4)',        1,          'less-than-or-equal with two equal arguments'],
    ['(<= 4 3)',        undef,      'less-than-or-equal with two arguments out of order'],
    ['(<= 2 3 4 4 5)',  1,          'less-than-or-equal with all but two items in order'],

    ['(>=)',            1,          'more-than-or-equal without arguments'],
    ['(>= 3)',          1,          'more-than-or-equal with single argument'],
    ['(>= 4 3)',        1,          'more-than-or-equal with multiple arguments in order'],
    ['(>= 6 5 4 3)',    1,          'more-than-or-equal with many arguments in order'],
    ['(>= 4 4)',        1,          'more-than-or-equal with two equal arguments'],
    ['(>= 3 4)',        undef,      'more-than-or-equal with two arguments out of order'],
    ['(>= 6 5 4 4 3)',  1,          'more-than-or-equal with all but two items in order'],

    ['(++ 3)',          4,          'increment with positive number'],
    ['(-- 4)',          3,          'decrement with positive number'],
    ['(++ -3)',         -2,         'increment with negative number'],
    ['(-- -4)',         -5,         'decrement with negative number'],

    ['(min 4 2 6 5)',   2,          'minimum'],
    ['(max 4 9 3 7)',   9,          'maximum'],

    ['(even? 2 4 6)',   1,          'even? with all even values'],
    ['(even? 2 3 4)',   undef,      'even? with all even but one odd value'],
    ['(odd? 3 5 7)',    1,          'odd? with all odd values'],
    ['(odd? 5 6 7)',    undef,      'odd? with all odd but one even value'],
);

my @should_fail = (

    ['(/ 3 0)',         [E_CAPTURED,    qr/zero/],          'division by zero'],

    ['(<=>)',           [E_PARAMETER,   qr/argument/],      'compare without arguments'],
    ['(<=> 3)',         [E_PARAMETER,   qr/argument/],      'compare with single argument'],
    ['(<=> 3 4 5)',     [E_PARAMETER,   qr/argument/],      'compare with too many arguments'],

    ['(==)',            [E_PARAMETER,   qr/argument/],      'equality without arguments'],
    ['(== 3)',          [E_PARAMETER,   qr/argument/],      'equality with single argument'],

    ['(!=)',            [E_PARAMETER,   qr/argument/],      'non-equality without arguments'],
    ['(!= 3)',          [E_PARAMETER,   qr/argument/],      'non-equality with single argument'],

    ['(++)',            [E_PARAMETER,   qr/single/],        'increment without arguments'],
    ['(++ 3 4)',        [E_PARAMETER,   qr/single/],        'increment with too many arguments'],

    ['(--)',            [E_PARAMETER,   qr/single/],        'decrement without arguments'],
    ['(-- 3 4)',        [E_PARAMETER,   qr/single/],        'decrement with too many arguments'],

    ['(min)',           [E_PARAMETER,   qr/one or more/],   'min without arguments'],
    ['(max)',           [E_PARAMETER,   qr/one or more/],   'max without arguments'],

    ['(even?)',         [E_PARAMETER,   qr/one or more/],   'even? without arguments'],
    ['(odd?)',          [E_PARAMETER,   qr/one or more/],   'odd? without arguments'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, qw( Data::Numbers ));

done_testing;
