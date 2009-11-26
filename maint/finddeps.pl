#!/usr/bin/env perl
use strict;
use warnings;

use MooseX::Declare;
use Class::MOP;
#use FindBin;
#use lib "$FindBin::Bin/../lib";

use Path::Class qw( dir );
my $path = shift
    or die "missing path argument";

my %used;
my %own;

unshift @INC, $path;
unshift @INC, sub {
    my (undef, $file) = @_;
    my $called_by = caller;
#    return unless $own{ $called_by };
    return unless $called_by =~ /\ALanguage::SX/;
    $used{ $file } = 1;
#    warn "CALLED $called_by\n";
    return undef;
};

dir($path)->recurse(callback => sub {
    my $entry = shift;
    return unless -f $entry;
    return unless $entry =~ /\.pm\Z/;
    my $pack = file_to_class("$entry");
    Class::MOP::load_class($pack);
    $own{ $pack }++;
#    require "$entry";
});

sub file_to_class {
    my $path = shift;
    my $norem = shift;
    $path =~ s/\.pm\Z//;
    my @parts = split /\//, $path;
    unless ($norem) {
        while (@parts) {
            my $found = shift @parts;
            last if $found eq 'lib';
        }
    }
    return join '::', @parts;
}

print "\n";
for my $class (map { file_to_class($_, 1) } sort keys %used) {
    printf "%s %s\n",
        $class,
        $class->VERSION ? sprintf('(%s)', $class->VERSION) : '';
}
