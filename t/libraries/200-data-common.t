#!/usr/bin/env perl
use strict;
use warnings;
use MooseX::Declare;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
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

    ['(empty?)',            1,      'empty? without arguments'],
    ['(empty? `())',        1,      'empty? with empty list'],
    ['(empty? {})',         1,      'empty? with empty hash'],
    ['(empty? "")',         1,      'empty? with empty string'],
    ['(empty? {} "")',      1,      'empty? with multiple empty arguments'],

    ['(empty? `(4))',       undef,  'empty? with non-empty list'],
    ['(empty? { x: 23 })',  undef,  'empty? with non-empty hash'],
    ['(empty? "foo")',      undef,  'empty? with non-empty string'],
    ['(empty? {} "x" `())', undef,  'empty? with not all empty arguments'],

    [['(exists? foo :bar)', $vars],     1,      'exists? on hash'],
    [['(exists? foo :baz)', $vars],     undef,  'exists? on hash without entry'],
    [['(exists? foo :bar 1)', $vars],   1,      'exists? deep on hash and list'],
    [['(exists? foo :bar 7)', $vars],   undef,  'exists? deep on hash and list without entry'],
    [['(exists? foo :obj :x)', $vars],  1,      'exists? deep on object'],
    [['(exists? foo :obj :y)', $vars],  undef,  'exists? deep on object without method'],

#   TODO works, but needs sorting to be tested
#    ['(keys { x: 2 y: 3 })',        [qw( x y )],        'keys on hash'],
    ['(keys `(2 3 4))',             [0, 1, 2],          'keys on list'],
#    ['(values { x: 2 y: 3 })',      [2, 3],             'values on hash'],
    ['(values `(2 3 4))',           [2, 3, 4],          'values on list'],
    ['(values { x: 2 y: 3 } `(y))', [3],                'values slice on hash'],
    ['(values `(2 3 4) `(1 2))',    [3, 4],             'values slice on list'],
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
);

with_libs(sub {

    is_result @$_ for @try;
    is_error  @$_ for @fails;

}, qw( Data::Common Quoting ));

done_testing;
