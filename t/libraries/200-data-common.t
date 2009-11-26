#!/usr/bin/env perl
use strict;
use warnings;
use MooseX::Declare;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

class TestObj {
    has x => (is => 'rw');
}

my $vars = {
    foo => { bar => [{ baz => 3 }, { qux => 4 }], obj => TestObj->new(x => [1, 2, 3]) },
};

my @try = (
    [   ['(at foo :bar 0 "baz")', $vars],
        3,
        'deep access of data structure',
    ],
    [   ['(at foo)', $vars],
        $vars->{foo},
        'deep access without path returns data structure',
    ],
    [   [q{(at foo 'bar 1 'qux)}, $vars],
        4,
        'access by quoted symbols',
    ],
    [   '(at `(1 2 3) 1)',
        2,
        'simple list access',
    ],
    [   ['(at foo :obj :x 2)', $vars],
        3,
        'object method access',
    ],
    [   ['(at foo "obj" :y 5)', $vars],
        undef,
        'non existent deep path with object method',
    ],

    ['(empty?)',                                1,                  'empty? without arguments'],
    ['(empty? `())',                            1,                  'empty? with empty list'],
    ['(empty? {})',                             1,                  'empty? with empty hash'],
    ['(empty? "")',                             1,                  'empty? with empty string'],
    ['(empty? {} "")',                          1,                  'empty? with multiple empty arguments'],

    ['(empty? `(4))',                           undef,              'empty? with non-empty list'],
    ['(empty? { x: 23 })',                      undef,              'empty? with non-empty hash'],
    ['(empty? "foo")',                          undef,              'empty? with non-empty string'],
    ['(empty? {} "x" `())',                     undef,              'empty? with not all empty arguments'],

    [['(exists? foo :bar)', $vars],             1,                  'exists? on hash'],
    [['(exists? foo :baz)', $vars],             undef,              'exists? on hash without entry'],
    [['(exists? foo :bar 1)', $vars],           1,                  'exists? deep on hash and list'],
    [['(exists? foo :bar 7)', $vars],           undef,              'exists? deep on hash and list without entry'],
    [['(exists? foo :obj :x)', $vars],          1,                  'exists? deep on object'],
    [['(exists? foo :obj :y)', $vars],          undef,              'exists? deep on object without method'],

    ['(sort (keys { x: 2 y: 3 }) cmp)',         [qw( x y )],        'keys on hash'],
    ['(keys `(2 3 4))',                         [0, 1, 2],          'keys on list'],

    ['(sort (values { x: 2 y: 3 }) <=>)',       [2, 3],             'values on hash'],

    ['(values `(2 3 4))',                       [2, 3, 4],          'values on list'],
    ['(values { x: 2 y: 3 } `(y))',             [3],                'values slice on hash'],
    ['(values `(2 3 4) `(1 2))',                [3, 4],             'values slice on list'],

    ['(length `(1 2 3 4))',                     4,                  'list length'],
    ['(length { x: 1 y: 2 })',                  2,                  'hash length'],
    ['(length "foobar")',                       6,                  'string length'],

    ['(defined?)',                              undef,              'defined? without arguments'],
    ['(defined? 0)',                            1,                  'defined? with single false but defined argument'],
    ['(defined? #f)',                           undef,              'defined? with single undefined argument'],
    ['(defined? 0 #f 3)',                       undef,              'defined? with mixed arguments'],
    ['(defined? 1 2 0 3)',                      1,                  'defined? with all defined but some false arguments'],

    ['(reverse `(1 2 3))',                      [3, 2, 1],          'reversing a list'],
    ['(reverse { x: 3 y: 4 })',                 {qw( 3 x 4 y )},    'reversing a hash'],
    ['(reverse "foobar")',                      'raboof',           'reversing a string'],

    [   q{
            (define hs { x: 2 y: 3 z: 4 })
            (define ls1 `(1 2 3 4))
            (define ls2 (append ls1))
            (list
              (set! (values hs `(x z)) `(8 9))
              (set! (values ls1) `(8 9))
              (set! (values ls2 `(1 2)) `(8 9))
              hs
              ls1
              ls2)
        },
        [   [8, 9],
            [8, 9],
            [8, 9],
            { x => 8, y => 3, z => 9 },
            [8, 9],
            [1, 8, 9, 4],
        ],
        'setting compound values',
    ],
    [   q/
            (define H  { x: 2 y: 3 })
            (define L1 `(1 2 3 4))
            (define L2 (append L1))
            (list
              (apply! 
                (values H `(x y))
                (-> (map _ ++)))
              (apply!
                (values L1)
                (-> (map _ list)))
              (apply!
                (values L2 `(1 3))
                (-> (map _ (-> { val: _ }))))
              H
              L1
              L2)
        /,
        [   [3, 4],
            [[1], [2], [3], [4]],
            [{ val => 2 }, { val => 4 }],
            { x => 3, y => 4 },
            [[1], [2], [3], [4]],
            [1, { val => 2 }, 3, { val => 4 }],
        ],
        'applying to compound values',
    ],
    [   q/
            (define call-count 0)
            (define (inc-count) 
              (apply! call-count ++))
            (define my-hash { x: 3 y: 4})
            (define (get-hash)
              (inc-count)
              my-hash)
            (define (get-keys)
              (inc-count)
              `(x y))
            (apply! 
              (values (get-hash) (get-keys)) 
              (-> (map _ ++)))
            call-count
        /,
        2,
        'evaluation count for apply! get/set path arguments',
    ],
);

my @fails = (
    ['(at)',                [E_PARAMETER,   qr/data structure/],    'deep access without arguments'],
    ['(at `(1 2 3) #f)',    [E_TYPE,        qr/path item/],         'deep access with undefined key'],

    ['(keys)',              [E_PARAMETER,   qr/argument/],          'keys without arguments'],
    ['(keys 23)',           [E_TYPE,        qr/hash or list/],      'keys with non-compound argument'],
    ['(keys {} 7)',         [E_PARAMETER,   qr/argument/],          'keys with too many arguments'],

    ['(values)',            [E_PARAMETER,   qr/argument/],          'values without arguments'],
    ['(values 23)',         [E_TYPE,        qr/hash or list/],      'values with non-compound argument'],
    ['(values {} 7)',       [E_TYPE,        qr/list/],              'values with non-list keys argument'],
    ['(values {} `() 8)',   [E_PARAMETER,   qr/argument/],          'values with too many arguments'],
    ['(values {} `(#f))',   [E_TYPE,        qr/undefined/],         'values of hash with undefined entry in key list'],
    ['(values `() `(#f))',  [E_TYPE,        qr/undefined/],         'values of list with undefiend entry in index list'],

    ['(length)',            [E_PARAMETER,   qr/not enough/],        'length without aguments'],
    ['(length "x" "y")',    [E_PARAMETER,   qr/too many/],          'length with more than one argument'],
    ['(length `foo)',       [E_TYPE,        qr/unable/],            'length of unknown item'],

    ['(reverse)',           [E_PARAMETER,   qr/not enough/],        'reverse without arguments'],
    ['(reverse 2 3)',       [E_PARAMETER,   qr/too many/],          'reverse with more than one argument'],
    ['(reverse `x)',        [E_TYPE,        qr/unable to/],         'reverse with non-reversible argument'],

    [   '(set! (values) `())',
        [E_PARAMETER,   qr/not enough/, 1, 7],
        'setting values without setter arguments',
    ],
    [   '(set! (values {}) `())',
        [E_PARAMETER,   qr/list of keys/, 1, 7],
        'setting hash values without setter key list argument',
    ],
    [   '(set! (values {} `() 3) `())',
        [E_PARAMETER,   qr/too many/, 1, 7],
        'setting hash values with more than two setter arguments',
    ],
    [   '(set! (values `() `() 3) `())',
        [E_PARAMETER,   qr/too many/, 1, 7],
        'setting list values with more than two setter arguments',
    ],
    [   '(set! (values 3 `()) `())',
        [E_TYPE,        qr/compound/, 1, 7],
        'setting values of a non-compound item',
    ],
    [   '(set! (values `() 3) `())',
        [E_TYPE,        qr/list/, 1, 7],
        'setting list values with a non-list setter argument',
    ],
    [   '(set! (values {} 3) `())',
        [E_TYPE,        qr/list/, 1, 7],
        'setting hash values with a non-list setter argument',
    ],
    [   '(set! (values {} `()) 3)',
        [E_TYPE,        qr/list/, 1, 1],
        'setting hash values with a non-list argument',
    ],
    [   '(set! (values `() `()) 3)',
        [E_TYPE,        qr/list/, 1, 1],
        'setting list values with a non-list argument',
    ],
    [   '(set! (values `() `(3 4)) `(3))',
        [E_PARAMETER,   qr/unable to save/, 1, 1],
        'setting three list elements to one value',
    ],
    [   '(set! (values {} `(x y)) `(3))',
        [E_PARAMETER,   qr/unable to save/, 1, 1],
        'setting three hash slots to one value',
    ],
    [   '(set! (values {} `(x #f)) `(3 4))',
        [E_TYPE,        qr/undefined/, 1, 7],
        'setting hash values with an undefined key',
    ],
    [   '(set! (values `() `(3 #f)) `(3 4))',
        [E_TYPE,        qr/undefined/, 1, 7],
        'setting list values with an undefined key',
    ],
);

with_libs(sub {

    is_result @$_ for @try;
    is_error  @$_ for @fails;

}, qw( Data::Common Quoting ScopeHandling Data::Numbers Data::Lists Data::Strings ));

done_testing;
