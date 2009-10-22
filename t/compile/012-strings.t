#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Constants qw( :all );
use Template::SX::Test      qw( :all );
use Test::Most;

is sx_run('"foo ${bar} baz"', { bar => 23 }), 'foo 23 baz', 'simple string interpolation';

is sx_run(
    '"list: ${ (join ", " x y z) }"',
    { join => sub { join shift, @_ }, x => 2, y => 3, z => 4 },
), 'list: 2, 3, 4', 'interpolation with inner string';


done_testing;
