#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

do {
    my $doc = sx_read 'foo ; bar';

    isa_ok $doc, 'Template::SX::Document', 'reader result';
    is $doc->node_count, 1, 'correct number of nodes';
    is $doc->get_node(0)->value, 'foo', 'correct symbol parsed';
};

do {
    my $doc = sx_read 'foo;bar';

    isa_ok $doc, 'Template::SX::Document', 'reader result';
    is $doc->node_count, 1, 'correct number of nodes';
    is $doc->get_node(0)->value, 'foo', 'correct symbol parsed';
};

do {
    my $doc = sx_read ';';

    isa_ok $doc, 'Template::SX::Document', 'reader result';
    is $doc->node_count, 0, 'correct number of nodes';
};

do {
    my $doc = sx_read 'foo;; ;;bar';

    isa_ok $doc, 'Template::SX::Document', 'reader result';
    is $doc->node_count, 1, 'correct number of nodes';
    is $doc->get_node(0)->value, 'foo', 'correct symbol parsed';
};

done_testing;
