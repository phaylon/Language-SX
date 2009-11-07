#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;
use Benchmark               qw( :all );

my @should_work = (

    [   '(list (include "simple.sx") (include "simple.sx"))',
        [[1, 2, 3], [1, 2, 3]],
        'simple include',
    ],
    [   q{
            (define content
              `((h1 "site heading")
                (p "site content")))
            `(html
              ,(include "head.sx" { title: "site title" })
              ,(include "body.sx" { content: content }))
        },
        [ bareword('html'),
          [ bareword('head'),
            [ bareword('title'),
              'site title' ],
            [ bareword('link'),
              { rel  => 'stylesheet',
                href => 'base.css',
                type => 'text/css',
              } ] ],
          [ bareword('body'),
            [ bareword('div'),
              { id => 'content' },
              [ bareword('h1'),
                'site heading' ],
              [ bareword('p'),
                'site content' ] ] ] ],
        'small html example',
    ],
    [   [   '(include file { param argument })', 
            { file => 'double.sxi', param => 'value', argument => 23 },
        ],
        46,
        'dynamic file, parameter and argument',
    ],

    [   q/
            (list
              (import "simple.sxm" { case: upper } format :group)
              (format "foobar")
              (double "foo"))
        /,
        [undef, 'FOOBAR', 'FOO FOO'],
        'importing from a simple module',
    ],
    [   q/
            (list
              (import "simple.sxm" { case: lower } format :group)
              (format "FooBar")
              (double "Foo"))
        /,
        [undef, 'foobar', 'foo foo'],
        'importing from a simple module with a different argument',
    ],
);

my @should_fail = (

    ['(import "simple.sxm" {})',                    [E_PARAMETER,   qr/missing.*case/],     'importing with missing argument'],
    ['(import "simple.sxm" { case: upper } foo)',   [E_SYNTAX,      qr/foo/],               'importing unknown export'],
    ['(import)',                                    [E_SYNTAX,      qr/expects/],           'import without arguments'],
    ['(import "simple.sxm" 23)',                    [E_TYPE,        qr/hash/],              'import with non-hash argument'],
    ['(import "NOTTHERE.sx")',                      [E_FILE,        qr/file/],              'importing non-existant file'],

    ['(include)',                                   [E_SYNTAX,      qr/expects/],           'include without arguments'],
    ['(include "simple.sxm" 23)',                   [E_TYPE,        qr/hash/],              'include with non-hash argument'],
    ['(include "simple.sxm" {} 23)',                [E_SYNTAX,      qr/expects/],           'include with more than two arguments'],
    ['(include "NOTTHERE.sx")',                     [E_FILE,        qr/file/],              'including non-existant file'],
    ['(include "simple.sxm")',                      [E_PARAMETER,   qr/missing.*case/],     'including with missing argument'],
);

with_libs(sub {
    sx_include_from '../sxlib';

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

    my $doc  = sx_read '(include "simple.sx")';
    my $time = timeit(5000, sub { @{ $doc->run } == 3 or die "wrong result in benchmark" });
    note('5000 includes took ', timestr($time));

}, qw( Data::Numbers Data::Functions Data::Strings Quoting ScopeHandling Data::Common Data::Lists Inserts ));

done_testing;
