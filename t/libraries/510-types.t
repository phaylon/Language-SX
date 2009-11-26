#!/usr/bin/env perl
use strict;
use warnings;
use Language::SX::Test          qw( :all );
use Language::SX::Constants     qw( :all );
use MooseX::Types::Moose        qw( Str Int ArrayRef HashRef );
use MooseX::Types::Path::Class  qw( File );
use Path::Class                 qw( file );
use Test::Most;
use Moose::Util::TypeConstraints;

my $M = '(import/types Moose) ';
my $P = '(import/types Moose Path::Class) ';

my @should_work = (

    ['(import/types (Moose Str)) Str',                                  Str,                            'importing simple type'],
    ['(import/types (Moose Str) (Path::Class File)) (list Str File)',   [Str, File],                    'importing from multiple libs'],
    ['(import/types (Moose Int Str)) (list Int Str)',                   [Int, Str],                     'importing multiple types'],
    ['(import/types Moose) (list Int Str)',                             [Int, Str],                     'importing all types from a library'],

    [$M . '(ArrayRef Int)',                                             ArrayRef[Int],                  'parameterized array reference type'],

    [$M . '((object-invocant Int) :check 3)',                           1,                              'type object-invocant'],
    [$M . '(map (list Int Str) HashRef)',                               [HashRef[Int], HashRef[Str]],   'mapping types'],

    [$M . '(type? Int)',                                                1,                              'type? with type argument'],
    [$M . '(type? 23)',                                                 undef,                          'type? with non-type argument'],
    [$M . '(type? Int Str ArrayRef)',                                   1,                              'type? with all-type arguments'],
    [$M . '(type? Int 3 Str)',                                          undef,                          'type? with mixed arguments'],

    [$M . '(isnt? Int 3)',                                              undef,                          'isnt? with valid value'],
    [$M . '(isnt? Int "foo")',                                          1,                              'isnt? with invalid value'],
    [$M . '(isnt? Int 3 4 5 6)',                                        undef,                          'isnt? with all-valid values'],
    [$M . '(isnt? Int 3 4 "x" 6)',                                      undef,                          'isnt? with mixed arguments'],
    [$M . '((isnt? Int) 3)',                                            undef,                          'isnt? generated predicate with valid value'],
    [$M . '((isnt? Int) "foo")',                                        1,                              'isnt? generated predicate with invalid value'],
    [$M . '((isnt? Int) 3 4 5 6)',                                      undef,                          'isnt? generated predicate with all-valid values'],
    [$M . '((isnt? Int) 3 4 "x" 6)',                                    undef,                          'isnt? generated predicate with mixed arguments'],

    [$M . '(is? Int 3)',                                                1,                              'is? with valid value'],
    [$M . '(is? Int "foo")',                                            undef,                          'is? with invalid value'],
    [$M . '(is? Int 3 4 5 6)',                                          1,                              'is? with all-valid values'],
    [$M . '(is? Int 3 4 "x" 6)',                                        undef,                          'is? with mixed arguments'],
    [$M . '((is? Int) 3)',                                              1,                              'is? generated predicate with valid value'],
    [$M . '((is? Int) "foo")',                                          undef,                          'is? generated predicate with invalid value'],
    [$M . '((is? Int) 3 4 5 6)',                                        1,                              'is? generated predicate with all-valid values'],
    [$M . '((is? Int) 3 4 "x" 6)',                                      undef,                          'is? generated predicate with mixed arguments'],

    [$M . '(grep (list 1 "foo" 2 "bar" 3) (is? Int))',                  [1, 2, 3],                      'grepping via is? predicate'],

    [$P . '(coerce File "/foo/bar.txt")',                               file('/foo/bar.txt'),           'coercing a value'],

    [$M . '(union Int Str)',                                            Int | Str,                      'type union'],
    [$M . '(union Int)',                                                Int,                            'type union with single argument'],

    [$M . '(enum "foo" :bar `baz)',                                     enum([qw( foo bar baz )]),      'enum'],

    [$M . '(enum->list (enum "foo" "bar" "baz"))',                      [qw( foo bar baz )],            'enum->list'],

    [$M . '(list->enum (list "foo" "bar" "baz"))',                      enum([qw( foo bar baz )]),      'list->enum'],
);

my @should_fail = (
    
    ['(import/types)',                      [E_SYNTAX,      qr/at least one/],                  'importing nothing'],
    ['(import/types 23)',                   [E_SYNTAX,      qr/bareword or list/,   1, 15],     'importing from a number'],
    ['(import/types ())',                   [E_SYNTAX,      qr/specification/,      1, 15],     'empty import specification'],
    ['(import/types (3 Foo))',              [E_SYNTAX,      qr/bareword/,           1, 16],     'importing from non-bareword library name'],
    ['(import/types (Foo))',                [E_SYNTAX,      qr/specification/,      1, 15],     'importing no types'],
    ['(import/types (Foo 3))',              [E_SYNTAX,      qr/bareword/,           1, 20],     'importing by a number'],

    ['(import/types Moose) (ArrayRef)',     [E_APPLY,       qr/parameter/],                     'calling a typeconstraint without argument'],

    ['(type?)',                             [E_PARAMETER,   qr/not enough/],                    'type? without arguments'],

    ['(isnt?)',                             [E_PARAMETER,   qr/not enough/],                    'isnt? without arguments'],
    ['(isnt? 23)',                          [E_TYPE,        qr/type/],                          'isnt? with non-type argument'],
    [$M . '((isnt? Int))',                  [E_PARAMETER,   qr/value to test/],                 'isnt? generated predicate without arguments'],

    ['(is?)',                               [E_PARAMETER,   qr/not enough/],                    'is? without arguments'],
    ['(is? 23)',                            [E_TYPE,        qr/type/],                          'is? with non-type argument'],
    [$M . '((is? Int))',                    [E_PARAMETER,   qr/value to test/],                 'is? generated predicate without arguments'],

    [$P . '(coerce)',                       [E_PARAMETER,   qr/not enough/],                    'coercing without arguments'],
    [$P . '(coerce File)',                  [E_PARAMETER,   qr/not enough/],                    'coercing with single argument'],
    [$P . '(coerce File "foo" 3)',          [E_PARAMETER,   qr/too many/],                      'coercing with more than two arguments'],
    [$P . '(coerce 3 "foo")',               [E_TYPE,        qr/type/],                          'coercing with non-type argument'],

    [$M . '(subtype)',                      [E_PARAMETER,   qr/not enough/],                    'subtype without arguments'],
    [$M . '(subtype 23)',                   [E_TYPE,        qr/type/],                          'subtype with non-type argument'],
    [$M . '(subtype Int foo: 3)',           [E_PARAMETER,   qr/options:.*foo/],                 'subtype with invalid option name'],
    [$M . '(subtype Int where: 3)',         [E_TYPE,        qr/code reference/],                'subtype with non-code where clause'],
    [$M . '(subtype Int message: {})',      [E_TYPE,        qr/code reference or string/],      'subtype with non-valid message option'],

    [$M . '(union)',                        [E_PARAMETER,   qr/not enough/],                    'type union without arguments'],
    [$M . '(union 23)',                     [E_TYPE,        qr/type/],                          'type union with non-type argument'],

    [$M . '(enum)',                         [E_PARAMETER,   qr/not enough/],                    'enum without arguments'],

    [$M . '(enum->list)',                   [E_PARAMETER,   qr/not enough/],                    'enum->list without arguments'],
    [$M . '(enum->list 23)',                [E_TYPE,        qr/enum/],                          'enum->list with non-type argument'],
    [$M . '(enum->list Int)',               [E_TYPE,        qr/enum/],                          'enum->list with non-enum argument'],
    [$M . '(enum->list (enum 2 3 4) 5)',    [E_PARAMETER,   qr/too many/],                      'enum->list with more than one argument'],

    [$M . '(list->enum)',                   [E_PARAMETER,   qr/not enough/],                    'list->enum without arguments'],
    [$M . '(list->enum 23)',                [E_TYPE,        qr/list/],                          'list->enum with non-list argument'],
    [$M . '(list->enum `(2 3) 4)',          [E_PARAMETER,   qr/too many/],                      'list->enum with more than one argument'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

    do {
        my $type = sx_run $M . q{ (subtype (ArrayRef Int) where: (-> (even? (length _))) message: (-> "invalid value '${_}'")) };
        ok $type->check([3, 4]), 'anonymous subtype works on valid value';
        ok not($type->check([5])), 'anonymous subtype works on invalid value';
        throws_ok { $type->assert_valid(3) } qr/invalid value '3'/, 'correct error message for type';
    };

}, 'Types', 'Data', 'ScopeHandling', 'Quoting');

done_testing;
