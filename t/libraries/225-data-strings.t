#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

my @should_work = (

    ['(string "foo" 23 `x)',                'foo23x',           'string construction'],

    ['(string? "foo")',                     1,                  'string predicate with single string argument'],
    ['(string? 23)',                        1,                  'string predicate with single integer argument'],
    ['(string? `foo)',                      undef,              'string predicate with single object argument'],
    ['(string? "foo" {} 23)',               undef,              'string predicate with mixed arguments'],
    ['(string? "foo" 23)',                  1,                  'string predicate with multiple defined non-reference arguments'],

    ['(eq? "foo" `foo)',                    1,                  'string equality with stringification'],
    ['(eq? "foo" "fo")',                    undef,              'string equality with non-equal strings'],
    ['(eq? "foo" "fo" "foo")',              undef,              'string equality with mixed strings'],

    ['(ne? "foo" "bar")',                   1,                  'string non-equality with two non-equals'],
    ['(ne? 3 4 5 6)',                       1,                  'string non-equality with many non-equals'],
    ['(ne? 3 4 5 3)',                       undef,              'string non-equality with far apart equals'],
    ['(ne? 3 4 4 5)',                       undef,              'string non-equality with close equals'],

    ['(lt?)',                               1,                  'less-than without aguments'],
    ['(lt? "foo")',                         1,                  'less-than with single argument'],
    ['(lt? "a" "b" "c")',                   1,                  'less-than with multiple ordered arguments'],
    ['(lt? "a" "b" "a")',                   undef,              'less-than with multiple non-ordered arguments'],

    ['(gt?)',                               1,                  'greater-than without aguments'],
    ['(gt? "foo")',                         1,                  'greater-than with single argument'],
    ['(gt? "c" "b" "a")',                   1,                  'greater-than with multiple ordered arguments'],
    ['(gt? "c" "b" "c")',                   undef,              'greater-than with multiple non-ordered arguments'],

    ['(le?)',                               1,                  'less-or-equal without aguments'],
    ['(le? "foo")',                         1,                  'less-or-equal with single argument'],
    ['(le? "a" "b" "c")',                   1,                  'less-or-equal with multiple ordered arguments'],
    ['(le? "a" "b" "a")',                   undef,              'less-or-equal with multiple non-ordered arguments'],

    ['(ge?)',                               1,                  'greater-or-equal without aguments'],
    ['(ge? "foo")',                         1,                  'greater-or-equal with single argument'],
    ['(ge? "c" "b" "a")',                   1,                  'greater-or-equal with multiple ordered arguments'],
    ['(ge? "c" "b" "c")',                   undef,              'greater-or-equal with multiple non-ordered arguments'],

    ['(upper "foO")',                       'FOO',              'upper'],

    ['(lower "FOo")',                       'foo',              'lower'],

    ['(upper-first "foO")',                 'FoO',              'upper-first'],

    ['(lower-first "FOo")',                 'fOo',              'lower-first'],

    ['(cmp :a :b)',                         -1,                 'comparing two strings in order'],
    ['(cmp :b :b)',                         0,                  'comparing two equal strings'],
    ['(cmp :b :a)',                         1,                  'comparing two strings in reverse order'],

    ['(split rx/_/ "a_b_c")',               [qw( a b c )],      'splitting a string'],
);

my @should_fail = (

    ['(string?)',               [E_PARAMETER,   qr/not enough/],    'string predicate without arguments'],

    ['(eq?)',                   [E_PARAMETER,   qr/two arguments/], 'string equality without arguments'],
    ['(eq? "foo")',             [E_PARAMETER,   qr/two arguments/], 'string equality with single argument'],

    ['(ne?)',                   [E_PARAMETER,   qr/two arguments/], 'string non-equality without arguments'],
    ['(ne? "foo")',             [E_PARAMETER,   qr/two arguments/], 'string non-equality with single argument'],

    ['(upper)',                 [E_PARAMETER,   qr/not enough/],    'upper without arguments'],
    ['(upper 3 4)',             [E_PARAMETER,   qr/too many/],      'upper with more than one argument'],

    ['(lower)',                 [E_PARAMETER,   qr/not enough/],    'lower without arguments'],
    ['(lower 3 4)',             [E_PARAMETER,   qr/too many/],      'lower with more than one argument'],

    ['(upper-first)',           [E_PARAMETER,   qr/not enough/],    'upper-first without arguments'],
    ['(upper-first 3 4)',       [E_PARAMETER,   qr/too many/],      'upper-first with more than one argument'],

    ['(lower-first)',           [E_PARAMETER,   qr/not enough/],    'lower-first without arguments'],
    ['(lower-first 3 4)',       [E_PARAMETER,   qr/too many/],      'lower-first with more than one argument'],

    ['(cmp)',                   [E_PARAMETER,   qr/not enough/],    'cmp without arguments'],
    ['(cmp :a)',                [E_PARAMETER,   qr/not enough/],    'cmp with single argument'],
    ['(cmp :a :b :c)',          [E_PARAMETER,   qr/too many/],      'cmp with more than two arguments'],

    ['(split)',                 [E_PARAMETER,   qr/not enough/],    'split without arguments'],
    ['(split rx/-/)',           [E_PARAMETER,   qr/not enough/],    'split with single argument'],
    ['(split rx/-/ "" 3)',      [E_PARAMETER,   qr/too many/],      'split with more than two arguments'],
    ['(split 3 4)',             [E_TYPE,        qr/regex/],         'split with non-regex argument'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, qw( Data::Lists Data::Numbers ScopeHandling Quoting Data::Functions Data::Common Data::Strings ));

done_testing;
