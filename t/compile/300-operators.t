#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

my @should_work = (
    
    ['(and 2 3 4)',                 4,          'and operator with all true'],
    ['(and 2 0 fnord)',             undef,      'and operator with false followed by failing'],

    ['(or 0 2 fnord 5)',            2,          'or operator with true followed by failing'],
    ['(or 0 0)',                    undef,      'or operator with all false'],

    ['(not 0)',                     1,          'not operator with single false argument'],
    ['(not 1)',                     undef,      'not operator with single true argument'],
    ['(not 0 0 0)',                 1,          'not operator with multiple false arguments'],
    ['(not 0 1 fnord 0)',           undef,      'not operator with true followed by failing'],

    ['(and-def 0 1 2)',             2,          'and-def operator with false but defined'],
    ['(and-def 1 #f fnord)',        undef,      'and-def operator with undefined followed by failing'],

    ['(or-def #f #f #f)',           undef,      'or-def with all undefined'],
    ['(or-def #f 0 fnord)',         0,          'or-def operator with false but defined followed by failing'],

    ['(not-def 0)',                 undef,      'not-def with single false but defined'],
    ['(not-def #f)',                1,          'not-def with single undefined'],
    ['(not-def #f #f #f)',          1,          'not-def with multiple undefined'],
    ['(not-def #f 0 fnord)',        undef,      'not-def with false but defined followed by failing'],

    ['(begin)',                     undef,      'begin operator without arguments'],
    ['(begin 23)',                  23,         'begin operator with single argument'],
    ['(begin 1 0 2 #f 3)',          3,          'begin operator with multiple arguments'],
);

my @should_fail = (

    ['(and)',               [E_SYNTAX,  qr/arguments/],     'and operator without arguments'],
    ['(and 3)',             [E_SYNTAX,  qr/arguments/],     'and operator with single argument'],

    ['(or)',                [E_SYNTAX,  qr/arguments/],     'or operator without arguments'],
    ['(or 3)',              [E_SYNTAX,  qr/arguments/],     'or operator with single argument'],

    ['(not)',               [E_SYNTAX,  qr/argument/],      'not operator without arguments'],

    ['(and-def)',           [E_SYNTAX,  qr/arguments/],     'and-def operator without arguments'],
    ['(and-def 3)',         [E_SYNTAX,  qr/arguments/],     'and-def operator with single argument'],

    ['(or-def)',            [E_SYNTAX,  qr/arguments/],     'or-def operator without arguments'],
    ['(or-def 3)',          [E_SYNTAX,  qr/arguments/],     'or-def operator with single argument'],

    ['(not-def)',           [E_SYNTAX,  qr/argument/],      'not-def operator without arguments'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, qw( Operators ));

done_testing;
