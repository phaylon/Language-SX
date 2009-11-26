#!/usr/bin/env perl
use strict;
use warnings;
use MooseX::Declare;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

role TestRole { }

class TestObj with TestRole { 
    method vals { 1, 2, 3 } 
    method cvals (ClassName $class:) { 1, 2, 3 } 
}

my @should_work = (

    ['(object? `foo)',                          1,                                  'object? with object argument'],
    ['(object? 23)',                            undef,                              'object? with non-object argument'],
    ['(object? `foo 3 `bar)',                   undef,                              'object? with mixed arguments'],
    ['(object? `x `y `z)',                      1,                                  'object? with all-object arguments'],

    ['(class-of `foo)',                         'Language::SX::Runtime::Bareword',  'class-of bareword'],

    ['((object-invocant `x) :value)',           'x',                                'object-invocant with bareword argument'],

    [   ['(apply/list (object-invocant obj) :vals `())', { obj => TestObj->new }],
        [1, 2, 3],
        'object-invocant in list context',
    ],

    ['((class-invocant "TestObj") :new)',       TestObj->new,                       'class-invocant with class name argument'],
    ['((class-invocant `x) new: value: "x")',   bareword('x'),                      'class-invocant with object argument'],

    [   ['(map (list "TestObj" obj) (-> (apply/list (class-invocant _) :cvals `())))', { obj => TestObj->new }],
        [[1, 2, 3], [1, 2, 3]],
        'class-invocant in list context',
    ],

    [   ['(is-a? obj "TestObj")', { obj => TestObj->new }],
        1,
        'is-a? on object argument',
    ],
    [   ['(is-a? obj "Fnord")', { obj => TestObj->new }],
        undef,
        'is-a? on object argument with non-parent class',
    ],

    ['(is-a? "TestObj" "Moose::Object")',       1,                                  'is-a? on class'],
    ['(is-a? "TestObj" "Fnord")',               undef,                              'is-a? on class with non-parent class'],
    ['(is-a? {} "Foo")',                        undef,                              'is-a? on other value'],

    [   ['(does? obj "TestRole")', { obj => TestObj->new }],
        1,
        'does? with object and consumed role',
    ],
    [   ['(does? obj "Fnord")', { obj => TestObj->new }],
        undef,
        'does? with object and non-consumed role',
    ],

    ['(does? "TestObj" "TestRole")',            1,                                  'does? on class with consumed role'],
    ['(does? "TestObj" "Foo")',                 undef,                              'does? on class with non-consumed role'],
    ['(does? {} "Foo")',                        undef,                              'does? on other value'],
);

my @should_fail = (

    ['(object?)',                   [E_PARAMETER,   qr/not enough/],        'object? without arguments'],

    ['(class-of)',                  [E_PARAMETER,   qr/not enough/],        'class-of without arguments'],
    ['(class-of `x `y)',            [E_PARAMETER,   qr/too many/],          'class-of with more than one argument'],
    ['(class-of 23)',               [E_TYPE,        qr/object/],            'class-of with non-object argument'],

    ['(object-invocant)',           [E_PARAMETER,   qr/not enough/],        'object-invocant without arguments'],
    ['(object-invocant `x 3)',      [E_PARAMETER,   qr/too many/],          'object-invocant with more than one argument'],
    ['(object-invocant 23)',        [E_TYPE,        qr/blessed reference/], 'object-invocant with non-object argument'],
    ['((object-invocant `x))',      [E_PARAMETER,   qr/method/],            'object-invocant invoked without method argument'],

    ['(class-invocant)',            [E_PARAMETER,   qr/not enough/],        'class-invocant without arguments'],
    ['(class-invocant :x :y)',      [E_PARAMETER,   qr/too many/],          'class-invocant with more than one argument'],
    ['(class-invocant {})',         [E_TYPE,        qr/blessed.*class/],    'class-invocant with non-blessed, non-string argument'],
    ['((class-invocant "Foo"))',    [E_PARAMETER,   qr/method/],            'class-invocant invoked without method argument'],

    ['(is-a?)',                     [E_PARAMETER,   qr/not enough/],        'is-a? without arguments'],
    ['(is-a? 2)',                   [E_PARAMETER,   qr/not enough/],        'is-a? with single argument'],
    ['(is-a? 2 3 4)',               [E_PARAMETER,   qr/too many/],          'is-a? with more than two arguments'],

    ['(does?)',                     [E_PARAMETER,   qr/not enough/],        'does? without arguments'],
    ['(does? 1)',                   [E_PARAMETER,   qr/not enough/],        'does? with single argument'],
    ['(does? 1 2 3)',               [E_PARAMETER,   qr/too many/],          'does? with more than two arguments'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, 'Data::Objects', 'Quoting', 'Data::Functions', 'Data::Lists', 'ScopeHandling');

done_testing;
