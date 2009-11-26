#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;
use MooseX::Declare;

class TestObj {
    has [qw( x y z )] => (is => 'rw');
    method double ($n) { $n * 2 }
}

my $vars = {
    obj => TestObj->new(
        x => 2,
        y => 3,
        z => 4,
    ),
};

my @should_work = (

    ['(hash)',                          {},                     'empty hash creation'],
    ['(hash x: 3)',                     { x => 3 },             'simple hash creation'],

    ['(hash? {})',                      1,                      'hash predicate with single hash'],
    ['(hash? 23)',                      undef,                  'hash predicate with single non-hash'],
    ['(hash? {} (hash))',               1,                      'hash predicate with multiple hashes'],
    ['(hash? {} 3 {})',                 undef,                  'hash predicate with mixed arguments'],

    ['(hash-ref { x: 3 } :x )',         3,                      'hash-ref'],
    ['(hash-ref { x: 3 } :y )',         undef,                  'hash-ref on non-existent key'],

    [   '(define h { x: 3 }) (list (set! (hash-ref h :y) 23) h)',
        [23, { x => 3, y => 23 }],
        'setting a slot in a hash',
    ],

    ['(merge { x: 3 } { y: 4 })',       { x => 3, y => 4 },     'merging two hashes'],
    ['(merge { x: 3 })',                { x => 3 },             'merging single hash'],
    ['(merge)',                         {},                     'merge without arguments'],
    ['(merge `(x 3) { y: 4 })',         { x => 3, y => 4 },     'merging a list with a hash'],
    ['(merge `(x) { y: 4 })',           { x => undef, y => 4 }, 'merging an odd list with a hash'],

    [   '(define (pairer hs) (hash-map hs (lambda p p))) (pairer { x: 3 y: 4 })',
        { x => [qw( x 3 )], y => [qw( y 4 )] },
        'hash-map',
    ],
    [   [   q{
                (define (dump-obj o)
                  `{ ,@(apply append (map `(x y z) (-> (list _ (obj _))))) })

                (list (dump-obj obj)
                      (hash-map 
                        { x:      13
                          y:      14
                          z:      15
                          double: 23 }
                        obj)
                      (dump-obj obj))
            },
            $vars,
        ],
        [   { x => 2,  y => 3,  z => 4 },
            { x => 13, y => 14, z => 15, double => 46 },
            { x => 13, y => 14, z => 15 },
        ],
        'hash-map with object applicant',
    ],

    [   '(hash-grep { a: 1 b: 2 c: 3 d: 4 } (lambda (k v) (even? v)))',
        { b => 2, d => 4 },
        'hash-grep',
    ],

    [   '(define h { x: 3 y: 4 z: 5 }) (list h (hash-splice h `(x z)) h)',
        [{qw( x 3 y 4 z 5 )}, {qw( x 3 z 5 )}, {qw( x 3 y 4 z 5 )}],
        'hash-splice',
    ],

    [   q{
            (define h { x: 3 y: 4 z: 5 })
            (list
              (set! (hash-splice h `(x z)) { a: 7 b: 8 })
              h)
        },
        [{ a => 7, b => 8 }, { y => 4, a => 7, b => 8 }],
        'setting a hash-splice',
    ],
    [   q{
            (define h { x: 3 y: 4 z: 5 })
            (list
              (apply! (hash-splice h `(x z))
                (-> { e: (at _ :x) f: (at _ :z) }))
              h)
        },
        [{ e => 3, f => 5 }, { e => 3, y => 4, f => 5 }],
        'setting a hash-splice via application',
    ],
);

my @should_fail = (

    ['(hash 3)',            [E_PARAMETER,   qr/even/],          'hash creation with odd number of arguments'],

    ['(hash?)',             [E_PARAMETER,   qr/not enough/],    'hash predicate without arguments'],

    ['(hash-ref)',          [E_PARAMETER,   qr/not enough/],    'hash-ref without arguments'],
    ['(hash-ref {})',       [E_PARAMETER,   qr/not enough/],    'hash-ref with single argument'],
    ['(hash-ref {} 3 4)',   [E_PARAMETER,   qr/too many/],      'hash-ref with more than two arguments'],
    ['(hash-ref 3 4)',      [E_TYPE,        qr/hash/],          'hash-ref with non-hash argument'],

    [   '(set! (hash-ref) 23)',
        [E_PARAMETER,   qr/not enough/, 1, 7],
        'setting a slot without setter arguments',
    ],
    [   '(set! (hash-ref {}) 23)',
        [E_PARAMETER,   qr/not enough/, 1, 7],
        'setting a slot without a setter key',
    ],
    [   '(set! (hash-ref {} 3 4) 23)',
        [E_PARAMETER,   qr/too many/, 1, 7],
        'setting a slot with more than two setter arguments',
    ],
    [   '(set! (hash-ref 3 4) 23)',
        [E_TYPE,        qr/hash/, 1, 7],
        'setting a slot on a non-hash',
    ],

    ['(merge 23)',              [E_TYPE,        qr/compound/],      'merging a non-compound'],

    ['(hash-map)',              [E_PARAMETER,   qr/not enough/],    'hash-map without arguments'],
    ['(hash-map {})',           [E_PARAMETER,   qr/not enough/],    'hash-map with single argument'],
    ['(hash-map {} + 3)',       [E_PARAMETER,   qr/too many/],      'hash-map with more than two arguments'],
    ['(hash-map 3 +)',          [E_TYPE,        qr/hash/],          'hash-map with non-hash argument'],
    ['(hash-map {} 3)',         [E_TYPE,        qr/applicant/],     'hash-map with non-applicant argument'],

    ['(hash-grep)',             [E_PARAMETER,   qr/not enough/],    'hash-grep without arguments'],
    ['(hash-grep {})',          [E_PARAMETER,   qr/not enough/],    'hash-grep with single argument'],
    ['(hash-grep {} + 3)',      [E_PARAMETER,   qr/too many/],      'hash-grep with more than two arguments'],
    ['(hash-grep 3 +)',         [E_TYPE,        qr/hash/],          'hash-grep with non-hash argument'],
    ['(hash-grep {} 3)',        [E_TYPE,        qr/applicant/],     'hash-grep with non-applicant argument'],

    ['(hash-splice)',           [E_PARAMETER,   qr/not enough/],    'hash-splice without arguments'],
    ['(hash-splice {})',        [E_PARAMETER,   qr/not enough/],    'hash-splice with single argument'],
    ['(hash-splice {} `() 2)',  [E_PARAMETER,   qr/too many/],      'hash-splice with more than two arguments'],
    ['(hash-splice 3 `())',     [E_TYPE,        qr/hash/],          'hash-splice with non-hash argument'],
    ['(hash-splice {} 3)',      [E_TYPE,        qr/list/],          'hash-splice with non-list argument'],
    ['(hash-splice {} `(#f))',  [E_TYPE,        qr/undefined/],     'hash-splice with undefined key list entry'],

    [   '(set! (hash-splice) {})',
        [E_PARAMETER,   qr/not enough/, 1, 7],
        'setting a hash-splice without setter arguments',
    ],
    [   '(set! (hash-splice {}) {})',
        [E_PARAMETER,   qr/not enough/, 1, 7],
        'setting a hash-splice with single setter argument',
    ],
    [   '(set! (hash-splice {} `() 7) {})',
        [E_PARAMETER,   qr/too many/, 1, 7],
        'setting a hash-splice with more than two setter arguments',
    ],
    [   '(set! (hash-splice 3 `()) {})',
        [E_TYPE,        qr/hash/, 1, 7],
        'setting a hash-splice with non-hash setter argument',
    ],
    [   '(set! (hash-splice {} 3) {})',
        [E_TYPE,        qr/list/, 1, 7],
        'setting a hash-splice with non-list setter argument',
    ],
    [   '(set! (hash-splice {} `()) 3)',
        [E_TYPE,        qr/hash/, 1, 1],
        'setting a hash-splice with non-hash argument',
    ],
    [   '(set! (hash-splice {} `(#f)) {})',
        [E_TYPE,        qr/undefined/, 1, 7],
        'setting a hash-splice with an undefined key',
    ],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, qw( Data::Lists Data::Numbers ScopeHandling Quoting Data::Functions Data::Common Data::Hashes ));

done_testing
