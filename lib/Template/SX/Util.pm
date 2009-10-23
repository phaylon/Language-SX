package Template::SX::Util;
use strict;
use warnings;

use TryCatch;
use Scalar::Util            qw( blessed );
use Template::SX::Types     qw( :all );
use Template::SX::Constants qw( :all );
use Data::Dump              qw( pp );
use Class::MOP;
use namespace::clean;

Class::MOP::load_class($_)
    for E_PROTOTYPE;

use Sub::Exporter -setup => {
    exports => [qw( apply_scalar )],
};

sub apply_scalar {
    my (%args) = @_;

    my ($op, $args) = @args{qw( apply arguments )};

    my @args = @$args;
    my $result;

    try {

        if (my $class = blessed $op) {
            
            E_PROTOTYPE->throw(
                class       => E_APPLY,
                attributes  => { message => "missing method argument for method call on $class instance" },
            ) unless @args;

            my $method = shift @args;

            $result = scalar $op->$method(@args);
        }
        elsif (ref $op eq 'CODE') {

            $result = scalar $op->(@args);
        }
        else {
            
            no warnings 'uninitialized';
            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => sprintf('invalid applicant type (%s): %s', ref($op), pp($op)) },
            );
        }
    } 
    catch (Template::SX::Exception::Prototype $e) {
        die $e;
    }
    catch (Template::SX::Exception $e) {
        die $e;
    }
    catch (Any $e) {
        E_PROTOTYPE->throw(
            class       => E_CAPTURED,
            attributes  => {
                message     => "error during application: $e",
                captured    => $e,
            },
        );
    }

    return $result;
}

1;
