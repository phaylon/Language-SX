package Language::SX::Util;
use strict;
use warnings;

use TryCatch;
use Scalar::Util            qw( blessed );
use Language::SX::Types     qw( :all );
use Language::SX::Constants qw( :all );
use Data::Dump              qw( pp );
use Class::MOP;
use namespace::clean;

Class::MOP::load_class($_)
    for E_PROTOTYPE, E_SYNTAX;

use Sub::Exporter -setup => {
    exports => [qw( 
        apply_scalar 
        document_loader
        deparse_parameter_spec
    )],
};

sub deparse_parameter_spec {
    my ($inf, $param) = @_;

    if ($param->isa('Language::SX::Document::Bareword')) {

        return $param->value;
    }
    elsif ($param->isa('Language::SX::Document::Cell::Application')) {

        E_SYNTAX->throw(
            message     => 'typed parameter specification requires at least a type and a name part',
            location    => $param->location,
        ) if $param->node_count < 2;

        my ($type, $name, @args) = $param->all_nodes;

        E_SYNTAX->throw(
            message     => 'name part of parameter specification is expected to be a bareword',
            location    => $name->location,
        ) unless $name->isa('Language::SX::Document::Bareword');

        my %option;
        while (my $option = shift @args) {

            E_SYNTAX->throw(
                message     => 'option name is expected to be a bareword',
                location    => $option->location,
            ) unless $option->isa('Language::SX::Document::Bareword');

            if ($option->value eq 'is') {

                my $trait = shift(@args) or E_SYNTAX->throw(
                    message     => 'expected trait name after is specification',
                    location    => $option->location,
                );

                E_SYNTAX->throw(
                    message     => 'expected trait name specification to be a bareword',
                    location    => $trait->location,
                ) unless $trait->isa('Language::SX::Document::Bareword');

                $option{is}{ $trait->value }++;
            }
            else {

                E_SYNTAX->throw(
                    message     => 'expected another value after ' . $option->value . ' option name',
                    location    => $option->location,
                ) unless @args;

                $option{ $option->value } = shift(@args)->compile($inf, SCOPE_FUNCTIONAL);
            }
        }

        return [$name->value, { type => $type->compile($inf, SCOPE_FUNCTIONAL), options => \%option }, $param->location];
    }
    else {

        E_SYNTAX->throw(
            message     => 'parameter list must be barewords or (Type name) specifications',
            location    => $param->location,
        );
    }
}

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

            my $sx = Language::SX->new(default_libraries => [@libs]);
            $sx->read(file => $file);
        };
    };
}

sub apply_scalar {
    my (%args) = @_;

    my ($op, $args, $to_list) = @args{qw( apply arguments to_list )};

    my @args = @$args;
    my $result;
    my $shadow_call = $Language::SX::SHADOW_CALL || sub { my $op = shift; goto $op };

#    warn "TRY";
    try {

        if (my $class = blessed $op) {

            if ($op->isa('Moose::Meta::TypeConstraint')) {

                E_PROTOTYPE->throw(
                    class       => E_APPLY,
                    attributes  => { message => 'creation of a parameterized type requires arguments' },
                ) unless @args;

                $result = $op->parameterize(@args);
            }
            else {
            
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
    catch (Language::SX::Exception::Prototype $e) {
        die $e;
    }
    catch (Language::SX::Exception $e) {
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
