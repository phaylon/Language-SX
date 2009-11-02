#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

do {
    my $example = q{
        (module (arguments foo . bar baz)
                (exports   (first: x) y)
                (requires "Data::Lists" Quoting ScopeHandling))
        (define x 3)
        (define y 4)
        (list foo bar baz x y)
    };

    my $doc = sx_read $example;
    my $res = $doc->run(vars => { foo => 23, bar => 7 });

    is_deeply $res, [23, 7, undef, 3, 4], 
        'module arguments and library loading';
    is_deeply [sort $doc->exported_groups], [qw( all first )],
        'export groups';
    is_deeply [sort $doc->exports_in_group('all')], [qw( x y )],
        'group of all exports';
    is_deeply [$doc->exports_in_group('first')], [qw( x )],
        'specific export group';
    is $doc->last_exported('x'), 3, 
        'exported value in group';
    is $doc->last_exported('y'), 4,
        'exported value in all group';

    throws_ok { $doc->run } E_PROTOTYPE, 'missing argument throws exception';
    like $@, qr/missing module argument.*foo/, 'correct error message';

    throws_ok { $doc->run(vars => { foo => 42, qux => 'BARK' }) } E_PROTOTYPE, 'unknown argument throws exception';
    like $@, qr/unknown module argument.*qux/, 'correct error message';
};

my @should_work = (

    ['(module) 23',         23,         'module definition without any specifics'],

    [   ['(module (requires Core) (arguments let)) (list (let 23))', { let => sub { shift() * 2 } }],
        [46],
        'arguments shadowing syntax element',
    ],
);

my @should_fail = (

    [   '(module 23)',
        [E_SYNTAX, qr/list arguments/, 1, 9],   
        'module declaration with non-list argument',
    ],
    [   '(module ())',
        [E_SYNTAX, qr/list arguments/, 1, 9],   
        'module declaration with non-list argument',
    ],
    [   '(module ((foo bar)))',
        [E_SYNTAX, qr/name/, 1, 10],
        'module declaration with non-bareword option name',
    ],
    [   '(module (fnord 7))',
        [E_SYNTAX, qr/fnord/, 1, 10],
        'module declaration with unknown option',
    ],
    [   '(module (exports x) (exports y))',
        [E_SYNTAX, qr/double declaration/, 1, 21],
        'module declaration with two export options',
    ],

    [   '(module (exports 23))',
        [E_SYNTAX, qr/bareword or list/, 1, 18],
        'exporting a constant',
    ],
    [   '(module (exports ()))',
        [E_SYNTAX, qr/empty/, 1, 18],
        'exporting a group without contents',
    ],
    [   '(module (exports (bar foo)))',
        [E_SYNTAX, qr/keyword/, 1, 19],
        'exporting a group without name',
    ],
    [   '(module (exports (foo: 23)))',
        [E_SYNTAX, qr/bareword/, 1, 24],
        'exporting a non-bareword in a group',
    ],

    [   '(module (requires 23))',
        [E_SYNTAX, qr/bareword or string constant/, 1, 19],
        'requiring a number as a library',
    ],

    [   '(module (arguments 3 . 4))',
        [E_SYNTAX, qr/bareword/, 1, 20],
        'numbers as arguments',
    ],
);

is_result @$_ for @should_work;
is_error  @$_ for @should_fail;

done_testing;
