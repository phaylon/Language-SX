package Template::SX::Test;
use strict;
use warnings;

use Test::More;
use Template::SX;
use Data::Dump qw( pp );
use Sub::Exporter -setup => {
    exports => [qw(
        is_result
        with_libs
        sx_read
        sx_load
        sx_run
        bareword
        dump_through
    )],
};

our $SX = Template::SX->new_with_traits(traits => [qw( CompileTidy )]);

sub bareword {
    my ($val) = @_;
    require Template::SX::Runtime::Bareword;
    return Template::SX::Runtime::Bareword->new(value => $val);
}

sub dump_through ($) {
    pp $_[0];
    return $_[0];
}

sub is_result {
    my ($code, $expect, $name) = @_;
    my $res = $SX->run('string', ref($code) ? ($code->[0], 'vars', $code->[1]) : $code);
#    pp $res;
    is_deeply $res, $expect, "correct result for $name";
}

sub sx_read {
    my $str = shift;
    return $SX->read_string($str);
}

sub sx_load {
    my $str = shift;
    return $SX->load(string => $str);
}

sub sx_run {
    my $str  = shift;
    my $args = shift;
    return $SX->run(string => $str, vars => $args || {});
}

sub with_libs (&@) {
    my ($code, @libs) = @_;
    local $SX = Template::SX->new_with_traits(
        traits      => [qw( CompileTidy )],
        libraries   => [@libs],
    );
    $code->();
}

1;
