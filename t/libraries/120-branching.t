#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Constants qw( :all );
use Template::SX::Test      qw( :all );
use Test::Most;

my @try = (

    ['(if 0 2 3)',      3,          'if with false and alternative'],
    ['(if 0 2)',        undef,      'if with false and no alternative'],
    ['(if 1 2 3)',      2,          'if with true and alternative'],
    ['(if 1 2)',        2,          'if with true and no alternative'],

    ['(unless 0 2 3)',  2,          'unless with false and alternative'],
    ['(unless 0 2)',    2,          'unless with false and no alternative'],
    ['(unless 1 2 3)',  3,          'unless with true and alternative'],
    ['(unless 1 2)',    undef,      'unless with true and no alternative'],

    [   q{
            (define (test args)
              (cond ((at args :foo)
                     :found-foo)
                    ((at args :bar)
                     => list)
                    ((at args :baz)
                     -> (* 2 _))
                    (#t :default)))
            (list
              (test { foo: 23 })
              (test { bar: 23 })
              (test { baz: 23 })
              (test {}))
        },
        ['found_foo', [23], 46, 'default'],
        'cond branch with multiple clauses',
    ],
    [   q{
            (define (test arg)
              (cond [arg :true]))
            (list
              (test #t)
              (test #f))
        },
        ['true', undef],
        'cond branch with no default clause',
    ],
);

my @fails = (

    ['(if)',                [E_SYNTAX,      qr/if condition/],              'if without arguments'],
    ['(if 1)',              [E_SYNTAX,      qr/if condition/],              'if with single argument'],
    ['(if 1 2 3 4)',        [E_SYNTAX,      qr/if condition/],              'if with more than 3 arguments'],

    ['(unless)',            [E_SYNTAX,      qr/unless condition/],          'unless without arguments'],
    ['(unless 1)',          [E_SYNTAX,      qr/unless condition/],          'unless with single argument'],
    ['(unless 1 2 3 4)',    [E_SYNTAX,      qr/unless condition/],          'unless with more than 3 arguments'],

    ['(cond)',              [E_SYNTAX,      qr/at least one clause/],       'cond without arguments'],
    ['(cond 23)',           [E_SYNTAX,      qr/list/,       1, 7],          'cond with non-list argument'],
    ['(cond ())',           [E_SYNTAX,      qr/clause/,     1, 7],          'cond with empty clause'],
    ['(cond (1))',          [E_SYNTAX,      qr/clause/,     1, 7],          'cond with single element in clause'],
    ['(cond (1 2 3 4))',    [E_SYNTAX,      qr/clause/,     1, 7],          'cond with more than three elements in clause'],
    ['(cond (1 2 3))',      [E_SYNTAX,      qr/bareword/,   1, 10],         'cond with non-bareword operator'],
    ['(cond (1 > 2))',      [E_SYNTAX,      qr/operator/,   1, 10],         'cond with invalid operator'],
    ['(cond (1 => 2))',     [E_TYPE,        qr/applicant/,  1, 13],         'cond with invalid applicant'],
);

with_libs(sub {

    is_result @$_ for @try;
    is_error  @$_ for @fails;

}, 'Branching', 'Data', 'ScopeHandling');

done_testing;


