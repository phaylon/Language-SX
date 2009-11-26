#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;
use Regexp::Compare         qw( is_less_or_equal );

my @should_work = (

    [   '(match "FooBar" rx/ (?<x> (?<y> o+ ) ba ) /i)',
        { x => 'ooBa', y => 'oo' },
        'simple named match',
    ],
    [   '(match "abc" rx/b/)',
        {},
        'simple match without captures',
    ],
    [   '(match "foo" rx/x/)',
        undef,
        'simple non-match',
    ],

    [   '(match-all "aeiaeioaeiou" (regex { val: rx/ ae (?: i (?: o (?: u )? )? )? / }))',
        [{ val => 'aei' }, { val => 'aeio' }, { val => 'aeiou' }],
        'simple match-all',
    ],
    [   '(match-all "foobar" rx/xyz/)',
        [],
        'simple non-matching match-all',
    ],

    ['(regex? rx//)',           1,          'regex? with regex argument'],
    ['(regex? 23)',             undef,      'regex? with non-regex argument'],
    ['(regex? rx/x/ rx/y/)',    1,          'regex? with all regex arguments'],
    ['(regex? rx/x/ 3 rx/y/)',  undef,      'regex? with mixed arguments'],

    [   q$
            (define rx 
              (regex { uri: (regex { schema: `("http" "https") }
                                   "://"
                                   { host:  rx/[a-z0-9\.-]+/i }
                                   { path:  rx/[^?]*/ }
                                   { query: rx/.*/ })
                       else: rx/.*/ }))
            (list
              (match "foobar" rx)
              (match "http://example.com/foo?bar" rx)
              (match "http://example.com?bar" rx)
              (match "https://example.com/foo" rx)
              (match "https://example.com" rx)
              (match "http://" rx))
        $,
        [   { else  => 'foobar' },
            { uri   => 'http://example.com/foo?bar', schema => 'http',  host => 'example.com', path => '/foo', query => '?bar' },
            { uri   => 'http://example.com?bar',     schema => 'http',  host => 'example.com', path => '',     query => '?bar' },
            { uri   => 'https://example.com/foo',    schema => 'https', host => 'example.com', path => '/foo', query => ''     },
            { uri   => 'https://example.com',        schema => 'https', host => 'example.com', path => '',     query => ''     },
            { else  => 'http://' },
        ],
        'complex deep regex match',
    ],

    [   '(replace "foObar" rx/(?<letter>o)/i (-> (string (at _ :letter) 0)))',
        'fo0O0bar',
        'simple search and replace',
    ],
);

my @regex_test = (

    ['(regex)',                 qr//,           'empty regex construction'],
    ['(regex 23)',              qr/23/,         'scalar regex interpolation'],
    ['(regex `(3 4 5))',        qr/3|4|5/,      'scalar list regex interpolation'],
    ['(regex 2 3 4)',           qr/234/,        'multi item regex interpolation'],
    ['(regex { x: 3 })',        qr/(?<x>3)/,    'scalar hash regex interpolation'],
    ['(regex `(rx/3/ ")"))',    qr/3|\)/,       'complex list regex interpolation'],
    ['(regex { x: rx/3/ })',    qr/(?<x>3)/,    'regex in list regex interpolation'],
    ['(regex ".")',             qr/\./,         'quoted scalar regex interpolation'],

    [   '(regex `("a" ("b" ".") ")"))',
        qr/a|(?:b|\.)|\)/,
        'nested list regex interpolation',
    ],
    [   '(regex { x: { y: "." } z: `(rx/./ "f") })',
        qr/ (?<x> (?<y> \.) ) | (?<z> (?: . | f ) ) /x,
        'nested hash regex interpolation',
    ],

    ['(string->regex ".")',     qr/./,          'string->regex'],
);

my @should_fail = (
    
    ['(match)',                 [E_PARAMETER,   qr/not enough/],            'match without arguments'],
    ['(match "foo")',           [E_PARAMETER,   qr/not enough/],            'match with single argument'],
    ['(match "foo" rx// 3)',    [E_PARAMETER,   qr/too many/],              'match with more than two arguments'],
    ['(match {} rx//)',         [E_TYPE,        qr/string/],                'matching non-string argument'],
    ['(match "" "bar")',        [E_TYPE,        qr/regex/],                 'matching against non-regex argument'],
    
    ['(match-all)',             [E_PARAMETER,   qr/not enough/],            'match-all without arguments'],
    ['(match-all "a")',         [E_PARAMETER,   qr/not enough/],            'match-all with single argument'],
    ['(match-all "b" rx// 3)',  [E_PARAMETER,   qr/too many/],              'match-all with more than two arguments'],
    ['(match-all {} rx//)',     [E_TYPE,        qr/string/],                'match-all non-string argument'],
    ['(match-all "" "bar")',    [E_TYPE,        qr/regex/],                 'match-all against non-regex argument'],

    ['(regex?)',                [E_PARAMETER,   qr/not enough/],            'regex? without arguments'],

    ['(regex `foo)',            [E_TYPE,        qr/transform/],             'bareword as regex part'],
    ['(regex `(x))',            [E_TYPE,        qr/transform/],             'bareword as regex list part item'],
    ['(regex { x: `x })',       [E_TYPE,        qr/transform/],             'bareword as regex hash part item'],

    ['(string->regex)',         [E_PARAMETER,   qr/not enough/],            'string->regex without arguments'],
    ['(string->regex 2 3)',     [E_PARAMETER,   qr/too many/],              'string->regex with more than one argument'],
    ['(string->regex {})',      [E_TYPE,        qr/string/],                'string->regex with non-string argument'],

    ['(replace)',               [E_PARAMETER,   qr/not enough/],            'replace without arguments'],
    ['(replace "x")',           [E_PARAMETER,   qr/not enough/],            'replace with single argument'],
    ['(replace "x" rx//)',      [E_PARAMETER,   qr/not enough/],            'replace with two arguments'],
    ['(replace "x" rx// 3 4)',  [E_PARAMETER,   qr/too many/],              'replace with more than three arguments'],
    ['(replace {} rx// at)',    [E_TYPE,        qr/string/],                'replacing in a non-string argument'],
    ['(replace "x" {} at)',     [E_TYPE,        qr/regex/],                 'replacing against non-regex argument'],
    ['(replace "x" rx// 3)',    [E_TYPE,        qr/lambda/],                'replacing by non-lambda argument'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

    for my $rx_test (@regex_test) {
        my ($code, $rx, $title) = @$rx_test;
        my $built = sx_run_timed $code, "$title";
        ok is_less_or_equal($built, $rx) && is_less_or_equal($rx, $built), "$title returns correct regex";
    }

}, qw( Data::Regex Data::Strings Data::Lists ScopeHandling Quoting Data::Common ));

done_testing;
