package Template::SX::Test;
use strict;
use warnings;

use Test::More;
use Template::SX;
use Sub::Exporter -setup => {
    exports => [qw(
        is_result
    )],
};

our $SX = Template::SX->new_with_traits(traits => [qw( CompileTidy )]);

sub is_result {
    my ($code, $expect, $name) = @_;
    is_deeply $SX->run('string', ref($code) ? ($code->[0], 'vars', $code->[1]) : $code), $expect, "correct result for $name";
}

1;
