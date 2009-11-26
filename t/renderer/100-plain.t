#!/usr/bin/env perl
use strict;
use warnings;
use aliased 'Language::SX::Renderer::Plain';
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

my @should_work = (
    ['`(html (body foo))',                  '<html><body>foo</body></html>',            'simple tags with bareword content'],
    ['`foo',                                'foo',                                      'simple bareword'],
    ['`(p "foo")',                          '<p>foo</p>',                               'element with string'],
    [['`(p "n is ${n}")', { n => 23 }],     '<p>n is 23</p>',                           'string with interpolation'],
    ['`(p { class: "foo" } foo)',           '<p class="foo">foo</p>',                   'string attribute'],
    ['`(p { class: foo } foo)',             '<p class="foo">foo</p>',                   'bareword attribute'],
    ['`(p { class foo } foo)',              '<p class="foo">foo</p>',                   'bareword attribute name'],
    ['`(p { class: (foo bar) } foo)',       '<p class="foo bar">foo</p>',               'multiple attribute values'],
    ['`(p foo bar)',                        '<p>foo bar</p>',                           'multiple content entries'],
    ['`(br)',                               '<br />',                                   'empty element'],
    ['`(input { name: foo })',              '<input name="foo" />',                     'empty element with attributes'],
    ['`(p foo () bar)',                     '<p>foo bar</p>',                           'empty node'],
    ['`(p "foo & bar")',                    '<p>foo &amp; bar</p>',                     'unsafe chars in contents'],
    ['`(a { href: "/foo?x=3&y=4" } foo)',   '<a href="/foo?x=3&amp;y=4">foo</a>',       'unsafe chars in attribute'],
    ['`(p "<foo>" (* "<foo>"))',            '<p>&lt;foo&gt; <foo></p>',                 'raw contents'],
    ['`(h1 foo)',                           '<h1>foo</h1>',                             'header'],
);

my @should_fail = (
    ['`(3 foo)',                            ['/',           qr/must be bareword/i],             'number as tag name'],
    ['`((p foo))',                          ['/',           qr/must be bareword/i],             'node as tag name'],
    ['`(html (3 foo))',                     ['//html[0]',   qr/must be bareword/i],             'deeper number as tag name'],
    ['`(html (-fnax foo))',                 ['//html[0]',   qr/invalid tag name/i],             'tag name with invalid chars'],
    ['`(p { + 23 })',                       ['//p',         qr/invalid attribute name/i],       'attribute name with invalid chars'],
);

with_libs(sub {

    my $renderer = Plain->new;
    for my $test (@should_work) {
        my ($expression, $expected, $title) = @$test;
        is  $renderer->render(sx_run(ref($expression) ? @$expression : $expression)),
            $expected,
            $title;
    }

    for my $test (@should_fail) {
        my ($expression, $error, $title) = @$test;
        my ($path, $msg_rx) = @$error;
        throws_ok { $renderer->render(sx_run($expression)) } $msg_rx, "$title raises correct error";
        like $@, qr/^at \Q$path:/, "$title error has correct path";
    }

}, 'Core');

done_testing;
