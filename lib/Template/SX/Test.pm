package Template::SX::Test;
use strict;
use warnings;

use Test::Most;
use Template::SX;
use FindBin;
use Data::Dump  qw( pp );
use Path::Class qw( file dir );
use Time::HiRes qw( gettimeofday tv_interval );
use Sub::Exporter -setup => {
    exports => [qw(
        is_result
        is_error
        with_libs
        sx_read
        sx_load
        sx_run
        sx_run_timed
        sx_include_from
        bareword
        dump_through
    )],
};

our $SX = Template::SX->new(document_traits => [qw( CompileTidy )], default_libraries => [], use_global_cache => 1);

sub sx_include_from {
    my $path = dir( $FindBin::Bin, shift );
    $SX = $SX->meta->clone_object($SX, include_path => $path);
}

sub bareword {
    my ($val) = @_;
    require Template::SX::Runtime::Bareword;
    return Template::SX::Runtime::Bareword->new(value => $val);
}

sub dump_through ($) {
    pp $_[0];
    return $_[0];
}

sub sx_run_timed {
    my ($code, $name) = @_;

    my ($expr, $vars) = ref($code) ? @$code : ($code, {});

    my $start = [gettimeofday];
    my $doc   = $SX->read(string => $expr);
    my $read  = [gettimeofday];
    my $cb    = $doc->loaded_callback;
    my $load  = [gettimeofday];
    my $res   = $doc->run(vars => $vars);
    my $run   = [gettimeofday];

    if ($ENV{TEMPLATE_SX_TIME}) {
        note('timings ' . ($name ? "for $name:" : ''));
        note('reading took ' . tv_interval($start, $read));
        note('loading took ' . tv_interval($read, $load));
        note('running took ' . tv_interval($load, $run));
    }

    return $res;
}

sub is_result {
    my ($code, $expect, $name) = @_;
    my $res;
    if ($ENV{TEMPLATE_SX_TIME}) {
        $res = sx_run_timed($code, $name);
    }
    else {
        $res = $SX->run('string', ref($code) ? ($code->[0], 'vars', $code->[1]) : $code);
    }
#    pp $res;
    is_deeply($res, $expect, "correct result for $name")
        or note 'received: ', pp($res);
}

sub is_error {
    my ($code, $err_spec, $name) = @_;
    my ($class, $msg, $line, $char) = @$err_spec;
    throws_ok { $SX->run('string', ref($code) ? ($code->[0], 'vars', $code->[1]) : $code) } $class, "$name raises exception";
    like $@, $msg, "$name has correct error message";
    is $@->location->{line}, $line, "$name has correct line number" if $line;
    is $@->location->{char}, $char, "$name has correct char number" if $char;
}

sub sx_read {
    my $str = shift;
    return $SX->read(string => $str);
}

sub sx_load {
    my $str = shift;
    my $doc = $SX->read(string => $str);
    return $doc->load;
}

sub sx_run {
    my $str  = shift;
    my $args = shift;
    return $SX->run(string => $str, vars => $args || {});
}

sub with_libs (&@) {
    my ($code, @libs) = @_;
    local $SX = Template::SX->new(
        document_traits     => [qw( CompileTidy )],
        default_libraries   => [@libs],
        use_global_cache    => 1,
    );
    $code->();
}

1;
