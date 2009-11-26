#!/usr/bin/env perl
use strict;
use warnings;
use Language::SX::Test      qw( :all );
use Language::SX::Constants qw( :all );
use Test::Most;

do {
    my $doc = sx_read 'foo ; bar';

    isa_ok $doc, 'Language::SX::Document', 'whitspaced comment reader result';
    is $doc->node_count, 1, 'correct number of nodes';
    is $doc->get_node(0)->value, 'foo', 'correct symbol parsed';
};

do {
    my $doc = sx_read 'foo;bar';

    isa_ok $doc, 'Language::SX::Document', 'non-whitespaced reader result';
    is $doc->node_count, 1, 'correct number of nodes';
    is $doc->get_node(0)->value, 'foo', 'correct symbol parsed';
};

do {
    my $doc = sx_read ';';

    isa_ok $doc, 'Language::SX::Document', 'comment-only reader result';
    is $doc->node_count, 0, 'correct number of nodes';
};

do {
    my $doc = sx_read 'foo;; ;;bar';

    isa_ok $doc, 'Language::SX::Document', 'multi-comment char reader result';
    is $doc->node_count, 1, 'correct number of nodes';
    is $doc->get_node(0)->value, 'foo', 'correct symbol parsed';
};

do {
    my $doc = sx_read '(foo (# bar) baz) (# qux) quux';

    isa_ok $doc, 'Language::SX::Document', 'cell comment reader result';
    is $doc->node_count, 2, 'correct number of nodes';
    is $doc->get_node(0)->node_count, 2, 'correct number of nodes in cell';
    is $doc->get_node(0)->get_node(0)->value, 'foo', 'first cell word';
    is $doc->get_node(0)->get_node(1)->value, 'baz', 'second cell word';
    is $doc->get_node(1)->value, 'quux', 'third word';
};

done_testing;
