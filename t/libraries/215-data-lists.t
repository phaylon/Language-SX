#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use MooseX::Declare;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

class TestObj { 
    has [qw( x y z n )] => (is => 'rw'); 
    method wrap (Str $arg) { "<$arg>" } 
}

my $vars = { obj => TestObj->new(x => 3, y => 4, z => 5, n => 0) };

my @should_work = (

    ['(map `(1 2 3) (-> (* _ 2)))',     [2, 4, 6],          'mapping a list'],
    ['(map `(3 4) (-> "v${_}"))',       [qw( v3 v4 )],      'mapping a list into strings'],
    [['(map `(x y) obj)', $vars],       [3, 4],             'mapping a list to an object'],

    ['(grep `(1 2 3 4) even?)',         [2, 4],             'grepping a list'],
    [['(grep `(x n) obj)', $vars],      [bareword('x')],    'grepping fields of an object'],

    ['(first `(1 2 3 4) even?)',        2,                  'first in a list'],
    [['(first `(n x F) obj)', $vars],   bareword('x'),      'first on object'],

    ['(sort `(5 3 4 1) <=>)',           [1, 3, 4, 5],       'sorting a list'],

    ['(reduce `(3 4 5) +)',             12,                 'reducing a list'],

    ['(list)',                          [],                 'empty list'],
    ['(list 1 2 3)',                    [1, 2, 3],          'list with contents'],

    ['(append `(1 2) `(3 4))',          [1, 2, 3, 4],       'appending two lists'],
    ['(append)',                        [],                 'append without arguments'],
    ['(append { x: 3 } `(5))',          ['x', 3, 5],        'appending a hash and a list'],

    ['(list? `(2 3))',                  1,                  'list predicate with single list'],
    ['(list? 23)',                      undef,              'list predicate with single non-list'],
    ['(list? `(2 3) `(4 5))',           1,                  'list predicate with multiple lists'],
    ['(list? `(2) {} `(5))',            undef,              'list predicate with mixed arguments'],

    ['(join "/" `( 3 4 5 ))',           '3/4/5',            'joining a list'],
    ['(join `- `(x y))',                'x-y',              'joining with barewords'],

    ['(head `(3 4 5))',                 3,                  'head of filled list'],
    ['(head `())',                      undef,              'head of empty list'],

    ['(tail `(3 4 5))',                 [4, 5],             'tail of filled list'],
    ['(tail `())',                      [],                 'tail of empty list'],

    ['(list-ref `(1 2 3) 1)',           2,                  'list-ref'],
    ['(list-ref `(1 2) 5)',             undef,              'list-ref on non-existent index'],

    ['(any? `(1 2 3) even?)',           1,                  'any? with true condition'],
    ['(any? `(1 3 5) (-> (> _ 7)))',    undef,              'any? with false condition'],

    ['(all? `(2 4 6) even?)',           1,                  'all? with true condition'],
    ['(all? `(3 4 5) odd?)',            undef,              'all? with false condition'],

    [   '(uniq `({ x: 1 } { x: 2 } { x: 1 }) (-> (at _ :x)))',
        [{ x => 1 }, { x => 2 }],
        'unique items of a list of hashes',
    ],

    ['(list-splice `(1 2 3 4 5) 1)',    [2, 3, 4, 5],       'list-splice with implicit length'],
    ['(list-splice `(1 2 3 4) 1 2)',    [2, 3],             'list-splice with explicit length'],
);

push @should_work, [
    '(define x (list 1 2 3)) (list (set! (list-ref x 1) 7) x)',
    [7, [1, 7, 3]],
    'setting a list element',
];

push @should_work, [
    '(n-at-a-time 3 `(1 2 3 4 5 6 7 8 9) (λ args args))',
    [[1, 2, 3], [4, 5, 6], [7, 8, 9]],
    'n-at-a-time with full list',
];

push @should_work, [
    '(n-at-a-time 3 `(1 2 3 4 5 6 7) (λ args args))',
    [[1, 2, 3], [4, 5, 6], [7, undef, undef]],
    'n-at-a-time with full list',
];

push @should_work, [
    q{  
        (define (collect-from-list take ls test)
          (apply take (grep ls test)))

        (let ((nums (list 1 2 3 4 5 6 7 8)))
          (list 
            (gather collect-from-list nums even?)
            (gather collect-from-list nums odd?)))
    },
    [[2, 4, 6, 8], [1, 3, 5, 7]],
    'gathering use case',
];

push @should_work, [
    q{
        (define ls1 `(2 3 4 5 6))
        (define ls2 (append ls1))
        (define new `(23 24 25))

        (list
          (set! (list-splice ls1 1) new)
          (set! (list-splice ls2 1 3) new)
          ls1 
          ls2)
    },
    [   [3, 4, 5, 6], 
        [3, 4, 5], 
        [2, 23, 24, 25], 
        [2, 23, 24, 25, 6],
    ],
    'setting a list-splice',
];

my @should_fail = (

    ['(map)',                   [E_PARAMETER,   qr/not enough/],    'map without arguments'],
    ['(map `(2 3))',            [E_PARAMETER,   qr/not enough/],    'map with single argument'],
    ['(map `(2) (-> _) 3)',     [E_PARAMETER,   qr/too many/],      'map with more than two arguments'],
    ['(map `(2) 3)',            [E_TYPE,        qr/applicant/],     'map with non-lambda'],
    ['(map 3 (-> _))',          [E_TYPE,        qr/list/],          'map with non-list'],

    ['(first)',                 [E_PARAMETER,   qr/not enough/],    'first without arguments'],
    ['(first `(2 3))',          [E_PARAMETER,   qr/not enough/],    'first with single argument'],
    ['(first `(2) (-> _) 3)',   [E_PARAMETER,   qr/too many/],      'first with more than two arguments'],
    ['(first `(2) 3)',          [E_TYPE,        qr/applicant/],     'first with non-lambda'],
    ['(first 3 (-> _))',        [E_TYPE,        qr/list/],          'first with non-list'],

    ['(reduce)',                [E_PARAMETER,   qr/not enough/],    'reduce without arguments'],
    ['(reduce `(2 3))',         [E_PARAMETER,   qr/not enough/],    'reduce with single argument'],
    ['(reduce `(2) + 3)',       [E_PARAMETER,   qr/too many/],      'reduce with more than two arguments'],
    ['(reduce `(2) 3)',         [E_TYPE,        qr/lambda/],        'reduce with non-lambda'],
    ['(reduce 3 +)',            [E_TYPE,        qr/list/],          'reduce with non-list'],

    ['(grep)',                  [E_PARAMETER,   qr/not enough/],    'grep without arguments'],
    ['(grep `(2 3))',           [E_PARAMETER,   qr/not enough/],    'grep with single argument'],
    ['(grep `(2) (-> _) 3)',    [E_PARAMETER,   qr/too many/],      'grep with more than two arguments'],
    ['(grep `(2) 3)',           [E_TYPE,        qr/applicant/],     'grep with non-lambda'],
    ['(grep 3 (-> _))',         [E_TYPE,        qr/list/],          'grep with non-list'],

    ['(sort)',                  [E_PARAMETER,   qr/not enough/],    'sort without arguments'],
    ['(sort `(2 3))',           [E_PARAMETER,   qr/not enough/],    'sort with single argument'],
    ['(sort `(2) <=> 3)',       [E_PARAMETER,   qr/too many/],      'sort with more than two arguments'],
    ['(sort `(2) 3)',           [E_TYPE,        qr/lambda/],        'sort with non-lambda'],
    ['(sort 3 <=>)',            [E_TYPE,        qr/list/],          'sort with non-list'],

    ['(append `() 23 `())',     [E_TYPE,        qr/compound/],      'append with non-compound argument'],

    ['(list?)',                 [E_PARAMETER,   qr/not enough/],    'list predicate without arguments'],

    ['(join)',                  [E_PARAMETER,   qr/not enough/],    'join without arguments'],
    ['(join ",")',              [E_PARAMETER,   qr/not enough/],    'join with single argument'],
    ['(join "," 3)',            [E_TYPE,        qr/list/],          'joining a non-list'],
    ['(join "," `(4) 7)',       [E_PARAMETER,   qr/too many/],      'join with more than two arguments'],

    ['(head)',                  [E_PARAMETER,   qr/not enough/],    'head without arguments'],
    ['(head `() 3)',            [E_PARAMETER,   qr/too many/],      'head with too many arguments'],
    ['(head 3)',                [E_TYPE,        qr/list/],          'head of non-list'],

    ['(tail)',                  [E_PARAMETER,   qr/not enough/],    'tail without arguments'],
    ['(tail `() 3)',            [E_PARAMETER,   qr/too many/],      'tail with too many arguments'],
    ['(tail 3)',                [E_TYPE,        qr/list/],          'tail of non-list'],

    ['(list-ref)',              [E_PARAMETER,   qr/not enough/],    'list-ref without arguments'],
    ['(list-ref `())',          [E_PARAMETER,   qr/not enough/],    'list-ref with single argument'],
    ['(list-ref `() 3 2)',      [E_PARAMETER,   qr/too many/],      'list-ref with too many arguments'],
    ['(list-ref 23 8)',         [E_TYPE,        qr/list/],          'list-ref on non-list'],

    ['(any?)',                  [E_PARAMETER,   qr/not enough/],    'any? without arguments'],
    ['(any? (list))',           [E_PARAMETER,   qr/not enough/],    'any? with single argument'],
    ['(any? (list) list? 3)',   [E_PARAMETER,   qr/too many/],      'any? with more than two arguments'],
    ['(any? 3 list?)',          [E_TYPE,        qr/list/],          'any? with non-list'],
    ['(any? (list) 3)',         [E_TYPE,        qr/applicant/],     'any? with non-applicant'],

    ['(all?)',                  [E_PARAMETER,   qr/not enough/],    'all? without arguments'],
    ['(all? (list))',           [E_PARAMETER,   qr/not enough/],    'all? with single argument'],
    ['(all? (list) list? 3)',   [E_PARAMETER,   qr/too many/],      'all? with more than two arguments'],
    ['(all? 3 list?)',          [E_TYPE,        qr/list/],          'all? with non-list'],
    ['(all? (list) 3)',         [E_TYPE,        qr/applicant/],     'all? with non-applicant'],

    [   '(set! (list-ref) 23)',
        [E_PARAMETER,   qr/not enough/, 1, 7],
        'setting an element without setter arguments',
    ],
    [   '(set! (list-ref (list)) 23)',
        [E_PARAMETER,   qr/not enough/, 1, 7],
        'setting an element without a setter index argument',
    ],
    [   '(set! (list-ref (list) 3 4) 23)',
        [E_PARAMETER,   qr/too many/, 1, 7],
        'setting an element with more than two setter arguments',
    ],
    [   '(set! (list-ref 3 4) 23)',
        [E_TYPE,        qr/list/, 1, 7],
        'setting an element on a non-list',
    ],

    [   '(n-at-a-time)',
        [E_PARAMETER, qr/not enough/],
        'n-at-a-time without arguments',
    ],
    [   '(n-at-a-time 3)',
        [E_PARAMETER, qr/not enough/],
        'n-at-a-time with single argument',
    ],
    [   '(n-at-a-time 3 `(1 2 3))',
        [E_PARAMETER, qr/not enough/],
        'n-at-a-time with two arguments',
    ],
    [   '(n-at-a-time 3 `(1 2 3) (lambda n n) 23)',
        [E_PARAMETER, qr/too many/],
        'n-at-a-time with more than three arguments',
    ],
    [   '(n-at-a-time 3 7 (lambda n n))',
        [E_TYPE, qr/list/],
        'n-at-a-time with non-list argument',
    ],
    [   '(n-at-a-time 3 `(1 2 3) 23)',
        [E_TYPE, qr/applicant/],
        'n-at-a-time with non-applicant argument',
    ],

    ['(gather)',        [E_PARAMETER,   qr/not enough/],    'gather without arguments'],
    ['(gather 23)',     [E_TYPE,        qr/lambda/],        'gather with non-lambda argument'],

    [   '(list-splice)',
        [E_PARAMETER,   qr/not enough/],
        'list-splice without arguments',
    ],
    [   '(list-splice `())',
        [E_PARAMETER,   qr/not enough/],
        'list-splice with single argument',
    ],
    [   '(list-splice `() 2 3 4)',
        [E_PARAMETER,   qr/too many/],
        'list-splice with more than three arguments',
    ],
    [   '(list-splice 1 2 3)',
        [E_TYPE,        qr/list/],
        'list-splice with non-list argument',
    ],

    ['(set! (list-splice) `())',            [E_PARAMETER,   qr/not enough/, 1, 7],  'setting a list-splice without arguments'],
    ['(set! (list-splice `()) `())',        [E_PARAMETER,   qr/not enough/, 1, 7],  'setting a list-splice with single argument'],
    ['(set! (list-splice `() 3 4 5) `())',  [E_PARAMETER,   qr/too many/, 1, 7],    'setting a list-splice with more than three arguments'],
    ['(set! (list-splice 3 4 5) `())',      [E_TYPE,        qr/list/, 1, 7],        'setting a list-splice on a non-list'],
    ['(set! (list-splice `() 3) 7)',        [E_TYPE,        qr/list/, 1, 1],        'setting a non-list as a list-splice'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, qw( Data::Lists Data::Numbers ScopeHandling Quoting Data::Functions Data::Common ));

done_testing;
