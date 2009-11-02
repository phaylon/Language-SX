#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $Template::SX::TRACK_INSTANCES = 1 }

use Template::SX;
use Template::SX::Inflator;
use Template::SX::Document;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;
use FindBin;

my $sx = Template::SX->new(include_path => "$FindBin::Bin/sxlib", use_global_cache => 1);
is instance_count('Template::SX::Inflator'),    0,          'no inflators alive before read';
is instance_count('Template::SX::Document'),    0,          'no document alive after read';
my $sx_count = instance_count('Template::SX');

my $doc = $sx->read(string => '(join ", " (include "simple.sx"))');
is instance_count('Template::SX::Inflator'),    0,          'no inflators alive after read';
is instance_count('Template::SX'),              $sx_count,  'sx count stayed the same after read';
is instance_count('Template::SX::Document'),    1,          'one document alive after read';

my $value = $doc->run;
is instance_count('Template::SX::Inflator'),    0,          'no inflators alive after run';
is instance_count('Template::SX'),              $sx_count,  'sx count stayed the same after run';
is instance_count('Template::SX::Document'),    2,          'two documents alive after run';

$doc->run;
is instance_count('Template::SX::Inflator'),    0,          'no inflators alive after second run';
is instance_count('Template::SX'),              $sx_count,  'sx count stayed the same after second run';
is instance_count('Template::SX::Document'),    2,          'two documents alive after second run';

undef $doc;
is instance_count('Template::SX::Inflator'),    0,          'no inflators alive after document removal';
is instance_count('Template::SX'),              $sx_count,  'sx count stayed the same after document removal';
is instance_count('Template::SX::Document'),    1,          'one (cached) document alive after document removal';

done_testing;


sub instance_count {
    my $class = shift;

    my @objects = $class->meta->get_all_instances;
    return scalar @objects;
}
