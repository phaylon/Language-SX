#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

my @should_work = (

    [   '(list->pairs `(1 2 3 4 5 6))', 
        [[1, 2], [3, 4], [5, 6]],
        'list->pairs',
    ],
    [   '(sort (hash->pairs { x: 1 y: 2 z: 3 }) (λ (p1 p2) (cmp (at p1 0) (at p2 0))))',
        [[x => 1], [y => 2], [z => 3]],
        'hash->pairs',
    ],
    [   '(compound->pairs `(1 2 3 4))',
        [[1, 2], [3, 4]],
        'compound->pairs with list argument',
    ],
    [   '(sort (compound->pairs { x: 1 y: 2 }) (λ (p1 p2) (cmp (at p1 0) (at p2 0))))',
        [[x => 1], [y => 2]],
        'compound->pairs with hash argument',
    ],

    ['(pair? `(1 2))',                      1,                  'pair? with single pair argument'],
    ['(pair? `(1 2) `(3))',                 undef,              'pair? with mixed arguments'],
    ['(pair? {})',                          undef,              'pair? with single non-list argument'],
    ['(pair? `(4))',                        undef,              'pair? with single non-pair argument'],

    ['(pairs? `((1 2) (3 4)))',             1,                  'pairs? with single pair list'],
    ['(pairs? `((3 4)) `((4 5) (5 6)))',    1,                  'pairs? with multiple pair lists'],
    ['(pairs? `((3 4)) `((5 4) (3)))',      undef,              'pairs? with mixed arguments'],
    ['(pairs? {})',                         undef,              'pairs? with non-list argument'],
    ['(pairs? `(23))',                      undef,              'pairs? with non pair list argument'],

    ['(pairs->list `((1 2) (3 4)))',        [qw( 1 2 3 4 )],    'pairs->list'],

    ['(pairs->hash `((x 2) (y 3)))',        {qw( x 2 y 3 )},    'pairs->hash'],
);

my @should_fail = (

    ['(list->pairs)',               [E_PARAMETER,   qr/not enough/],        'list->pairs without arguments'],
    ['(list->pairs `() 3)',         [E_PARAMETER,   qr/too many/],          'list->pairs with more than one argument'],
    ['(list->pairs 3)',             [E_TYPE,        qr/list/],              'list->pairs with non-list argument'],

    ['(hash->pairs)',               [E_PARAMETER,   qr/not enough/],        'hash->pairs without arguments'],
    ['(hash->pairs {} 3)',          [E_PARAMETER,   qr/too many/],          'hash->pairs with more than one argument'],
    ['(hash->pairs 3)',             [E_TYPE,        qr/hash/],              'hash->pairs with non-hash argument'],

    ['(compound->pairs)',           [E_PARAMETER,   qr/not enough/],        'compound->pairs without arguments'],
    ['(compound->pairs {} 3)',      [E_PARAMETER,   qr/too many/],          'compound->pairs with more than one argument'],
    ['(compound->pairs 3)',         [E_TYPE,        qr/compound/],          'compound->pairs with non-compound argument'],

    ['(pair?)',                     [E_PARAMETER,   qr/not enough/],        'pair? without arguments'],

    ['(pairs?)',                    [E_PARAMETER,   qr/not enough/],        'pairs? without arguments'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, qw( Data::Lists Data::Hashes Data::Pairs Quoting ScopeHandling Data::Common Data::Strings ));

done_testing;
