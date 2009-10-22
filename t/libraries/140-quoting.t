#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Constants qw( :all );
use Template::SX::Test      qw( :all );
use Test::Most;
use Data::Dump              qw( pp );

use aliased 'Template::SX::Runtime::Bareword';

my @quoted = (
    [q('23),            23,         'quoted constant evaluates to constant'],
    [q{'()},            [],         'quoted list'],
    [q{'(1 2 3)},       [1, 2, 3],  'quoted list of constants'],
    [q{'"foo"},         'foo',      'quoted string constant'],
    [q{'("foo")},       ['foo'],    'quoted list with string constant'],
    [q{'"${(+ 2 3)}"},  '5',        'quoted string with interpolation unquotes'],
    [q{'"${'23}"},      '23',       'quoted string with interpolated, quoted constant'],

    [   q{(quote foo)},
        bareword('foo'),
        'explicit quote',
    ],

    [   q{'foo},
        bareword('foo'),
        'quoted bareword',
    ],
    [   q{'(foo bar)},
        [bareword('foo'), bareword('bar')],
        'quoted list with barewords',
    ],

    [   q{'((foo 23) (bar "baz"))},
        [[bareword('foo'), 23], [bareword('bar'), 'baz']],
        'quoted complex',
    ],
);

my @quasiquoted = (

    [   q{`23},
        23,
        'quasiquoted constant',
    ],

    [   q{`foo},
        bareword('foo'),
        'quasiquoted bareword',
    ],

    [   q{`(foo 23)},
        [bareword('foo'), 23],
        'quasiquoted list with bareword and constant',
    ],

    [   q{`,23},
        23,
        'quasiquoted and directly unquoted constant',
    ],
    [   q{`("foo: " ,(+ 2 3))},
        ['foo: ', 5],
        'quasiquoted list withh string constant and application',
    ],
    [   q{`(,23)},
        [23],
        'quasiquoted constant in list',
    ],
    [   q{((lambda args `(x ,@args y)) 1 2 3)},
        [bareword('x'), 1, 2, 3, bareword('y')],
        'quasiquotation with spliced unquote',
    ],
);

with_libs(sub {

    is_result @$_ for @quoted, @quasiquoted;

    for my $quote (qw( quote quasiquote )) {

        throws_ok { sx_load "($quote foo bar)" } E_SYNTAX, "$quote with two args throws syntax error";
        like $@, qr/quot/, 'correct error message';
        is $@->location->{line}, 1, 'correct line number';
        is $@->location->{char}, 1, 'correct char number';

        throws_ok { sx_load "($quote)" } E_SYNTAX, "$quote with no args throws syntax error";
        like $@, qr/quot/, 'correct error message';
        is $@->location->{line}, 1, 'correct line number';
        is $@->location->{char}, 1, 'correct char number';
    }

    throws_ok { sx_load q{`,@foo} } E_SYNTAX, 'trying to splice into current node throws exception';
    like $@, qr/unquote/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 2, 'correct char number';

    is_deeply sx_run(q{ `(html (head (title ,title)) (body ,message)) }, { title => 'Test', message => 'Hello' }),
        [bareword('html'), [bareword('head'), [bareword('title'), 'Test']], [bareword('body'), 'Hello']],
        'simple html test';

}, 'Quoting', 'Math', 'ScopeHandling');

done_testing;
