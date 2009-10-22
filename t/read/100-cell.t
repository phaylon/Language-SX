#!/usr/bin/env perl
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

throws_ok { sx_read '(foo}' } E_SYNTAX, 'wrong cell closer exception';
like $@, qr/expected cell to be closed/i, 'correct error message';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 5, 'correct char number';

throws_ok { sx_read '(foo' } E_SYNTAX, 'unclosed cell exception';
like $@, qr/unexpected end of stream/i, 'correct error message';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 1, 'correct char number';

do {
    my $doc = sx_read '(foo) [foo]';
    is $doc->node_count, 2, 'document contains two nodes';
    isa_ok $doc->get_node(0), 'Template::SX::Document::Cell::Application', 'normally parenthesized cell';
    isa_ok $doc->get_node(1), 'Template::SX::Document::Cell::Application', 'bracketed cell';
};

done_testing;
