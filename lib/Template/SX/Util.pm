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
    exports => [qw( 
        apply_scalar 
        document_loader
    )],
};

sub document_loader {
    my ($cache, $key, $libs) = @_;

    my @libs = @$libs;

    return sub {
        my ($file) = @_;

        E_PROTOTYPE->throw(
            class       => E_INSERT,
            attributes  => { message => "unable to load non-existing file $file", path => $file },
        ) unless -e $file;

        return $cache->{ $file }{ $key }
            if exists $cache->{ $file }{ $key };

        return $cache->{ $file }{ $key } ||= do {

            my $sx = Template::SX->new(default_libraries => [@libs]);
            $sx->read(file => $file);
        };
    };
}

sub apply_scalar {
    my (%args) = @_;

    my ($op, $args, $to_list) = @args{qw( apply arguments to_list )};

    my @args = @$args;
    my $result;
    my $shadow_call = $Template::SX::SHADOW_CALL || sub { my $op = shift; goto $op };

#    warn "TRY";
    try {

        if (my $class = blessed $op) {
            
            E_PROTOTYPE->throw(
                class       => E_APPLY,
                attributes  => { message => "missing method argument for method call on $class instance" },
            ) unless @args;

            my $method = shift @args;

#            $result = scalar $op->
#            $result = scalar $op->$method(@args);
            unless (ref $method eq 'CODE') {
                my $found_method = $op->can($method)
                    or E_PROTOTYPE->throw(
                        class       => E_APPLY,
                        attributes  => { 
                            message => sprintf(
                                q(unable to find a method named '%s' on instance of '%s'),
                                $method,
                                blessed($op),
                            ),
                        },
                    );
                $method = $found_method;
            }

            $result = $to_list ? [$shadow_call->($method, $op, @args)] : scalar($shadow_call->($method, $op, @args));
        }
        elsif (ref $op eq 'CODE') {

            $result = $to_list ? [$shadow_call->($op, @args)] : scalar($shadow_call->($op, @args));
#            $result = scalar $op->(@args);
        }
        else {
            
            no warnings 'uninitialized';
            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => sprintf('invalid applicant type (%s): %s', ref($op), pp($op)) },
            );
        }

#        warn "RES";
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
