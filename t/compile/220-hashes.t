#!/usr/bin/env perl
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

is_deeply sx_run('{ "foo" 23 }'), { foo => 23 }, 'simple hash';
is_deeply sx_run(q/{ 'foo "is ${ (+ 3 4) }" }/), { foo => 'is 7' }, 'more complex hash';

done_testing;
