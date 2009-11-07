#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Data::Dump              qw( pp );
use Test::Most;

do {
    my $doc = sx_read q{ "foo" "foo;bar " "" "ba\nz" };

    isa_ok $doc, 'Template::SX::Document', 'simple strings result';
    is $doc->node_count, 4, 'correct amount of strings';

    isa_ok $doc->get_node($_), 'Template::SX::Document::String::Constant', "item $_ is a constant string"
        for 0 .. 3;

    is $doc->get_node(0)->value, 'foo', 'simple string';
    is $doc->get_node(1)->value, 'foo;bar ', 'string with comment delimiter in it';
    is $doc->get_node(2)->value, '', 'empty string';
    is $doc->get_node(3)->value, "ba\nz", 'string with newline';
};

do {
    my $doc = sx_read q("foo ${ bar } baz");
    isa_ok $doc, 'Template::SX::Document', 'interpolated string result';
    is $doc->node_count, 1, 'correct amount of strings';

    my $str = $doc->get_node(0);
    isa_ok $str, 'Template::SX::Document::String';
    is $str->string_part_count, 3, 'correct amount of string parts';

    my ($foo, $bar, $baz) = $str->all_string_parts;
    isa_ok $foo, 'Template::SX::Document::String::Constant', 'starting string part';
    is ref($bar), 'ARRAY', 'interpolated value represented by list';
    is scalar(@$bar), 1, 'list contains one value';
    isa_ok $bar->[0], 'Template::SX::Document::Bareword', 'list contains a bareword';
    isa_ok $baz, 'Template::SX::Document::String::Constant', 'ending string part';
    is $foo->value, 'foo ', 'first constant has correct value';
    is $bar->[0]->value, 'bar', 'correct bareword in interpolation';
    is $baz->value, ' baz', 'second constant has correct value';
};

do {
    my $doc = sx_read q("${foo}");
    isa_ok $doc, 'Template::SX::Document', 'tight interpolated string result';
    is $doc->node_count, 1, 'correct amount of strings';

    my $str = $doc->get_node(0);
    isa_ok $str, 'Template::SX::Document::String';
    is $str->string_part_count, 3, 'correct amount of string parts';

    my ($left, $foo, $right) = $str->all_string_parts;
    is $left->value, '', 'left string is empty';
    is $right->value, '', 'right string is empty';
    is $foo->[0]->value, 'foo', 'correct bareword';
};

do {
    my $doc = sx_read q(before "foo ${ 23 (join ", " x y z) } bar" after);
    isa_ok $doc, 'Template::SX::Document', 'nested string result';
    is $doc->node_count, 3, 'correct amount of strings';

    my ($before, $str, $after) = $doc->all_nodes;

    isa_ok $before, 'Template::SX::Document::Bareword';
    isa_ok $after, 'Template::SX::Document::Bareword';
    is $before->value, 'before', 'correct bareword before string';
    is $after->value, 'after', 'correct bareword after string';

    isa_ok $str, 'Template::SX::Document::String';
    is $str->string_part_count, 3, 'correct amount of string parts';

    my ($foo, $inter, $bar) = $str->all_string_parts;

    isa_ok $foo, 'Template::SX::Document::String::Constant';
    isa_ok $bar, 'Template::SX::Document::String::Constant';
    is $foo->value, 'foo ', 'first string constant part';
    is $bar->value, ' bar', 'last string constant part';
    is ref($inter), 'ARRAY', 'interpolated string part';
    is scalar(@$inter), 2, 'correct number of entries in substream';
    
    my ($num, $apply) = @$inter;

    isa_ok $num, 'Template::SX::Document::Number';
    isa_ok $apply, 'Template::SX::Document::Cell::Application';
    is $apply->node_count, 5, 'correct number of nodes in application';
    
    my ($join, $sep, $x, $y, $z) = $apply->all_nodes;

    isa_ok $join, 'Template::SX::Document::Bareword';
    isa_ok $sep, 'Template::SX::Document::String::Constant';
    isa_ok $x, 'Template::SX::Document::Bareword';
    isa_ok $y, 'Template::SX::Document::Bareword';
    isa_ok $z, 'Template::SX::Document::Bareword';
    is $join->value, 'join', 'correct applicant';
    is $sep->value, ', ', 'correct separator string constant';
    is $x->value, 'x', 'first variable';
    is $y->value, 'y', 'second variable';
    is $z->value, 'z', 'third variable';
};

do {
    my $doc = sx_read q{  »
            foo bar
            baz qux
        «
    };
    isa_ok $doc->get_node(0), 'Template::SX::Document::String::Constant';
    is $doc->get_node(0)->value, "foo bar\nbaz qux", 'correct multiline string';
};

throws_ok { sx_read 'foo " bar' } E_SYNTAX, 'string without end';
like $@, qr/runaway/, 'correct error message';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 5, 'correct char number';

throws_ok { sx_read '"x $y z"' } E_SYNTAX, 'invalid interpolation';
like $@, qr/interpolation/, 'correct error message';
is $@->location->{line}, 1, 'correct line number';
is $@->location->{char}, 5, 'correct char number';

done_testing;
