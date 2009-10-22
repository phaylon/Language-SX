use MooseX::Declare;

class Template::SX::Library::ScopeHandling extends Template::SX::Library {
    use MooseX::MultiMethods;
    use MooseX::ClassAttribute;
    use CLASS;

    use Scalar::Util            qw( blessed );
    use Data::Dump              qw( pp );
    use Template::SX::Constants qw( :all );
    Class::MOP::load_class($_)
        for E_SYNTAX, E_RESERVED;

    class_has '+function_map';
    class_has '+syntax_map';

    CLASS->add_syntax(define => sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        return $self->compile_definition($inf, $cell, @_);
    });

    multi method compile_definition (Object $inf, Object $cell, Template::SX::Document::Bareword $variable, Object $source) {

        $inf->assure_unreserved_identifier($variable);

        return $self->_render_definition(
            $inf, 
            $cell, 
            $variable->value, 
            $source->compile($inf, SCOPE_FUNCTIONAL),
        );
    }

    multi method compile_definition (Object $inf, Object $cell, Template::SX::Document::Bareword $variable) {

        $inf->assure_unreserved_identifier($variable);

        return $self->_render_definition(
            $inf, 
            $cell, 
            $variable->value, 
            'sub { undef }',
        );
    }

    multi method compile_definition (Object $inf, Object $cell)
        { $self->_throw_define_exception($inf, $cell) }

    multi method compile_definition (Object $inf, Object $cell, $)
        { $self->_throw_define_exception($inf, $cell) }

    multi method compile_definition (Object $inf, Object $cell, $, $)
        { $self->_throw_define_exception($inf, $cell) }

    multi method compile_definition (Object $inf, Object $cell, $, $, $, @)
        { $self->_throw_define_exception($inf, $cell) }

    method _render_definition (Object $inf, Object $cell, Str $name, Str $source) {

        return $inf->render_call(
            library     => $CLASS,
            method      => 'make_definition',
            args        => {
                name    => pp($name),
                source  => $source,
            },
        );
    }

    method _throw_define_exception (Object $inf, Object $cell) {

        E_SYNTAX->throw(
            message     => 'invalid definition syntax',
            location    => $cell->location,
        );
    }

    CLASS->add_syntax(lambda => sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        E_SYNTAX->throw(
            message     => sprintf(
                'lambda needs at least 2 arguments (parameter specification and body), you gave %d', 
                scalar(@_),
            ),
            location    => $cell->location,
        ) unless @_ == 2;

        my ($signature, @body) = @_;

        my $deparsed = $self->deparse_signature($inf, $signature);

        $inf->render_call(
            library => $CLASS,
            method  => 'make_lambda_generator',
            args    => {
                %$deparsed,
                sequence => $inf->render_sequence(\@body),
            },
        );
    });

    method make_lambda_generator (
        CodeRef         :$sequence!,
        Bool            :$has_max,
        Bool            :$has_min,
        Int             :$max?,
        Int             :$min?,
        ArrayRef[Str]   :$positionals,
        Str             :$rest_var?
    ) {

        return sub {
            my $env = shift;

            return sub {

                # FIXME throw exceptions
                die "not enough arguments"  if $has_min and $min > @_;
                die "too many arguments"    if $has_max and $max < @_;

                my %vars;
                $vars{ $_ } = shift
                    for @$positionals;

                $vars{ $rest_var } = [@_]
                    if $rest_var;

                return $sequence->({ vars => \%vars, parent => $env });
            };
        };
    }

    method deparse_signature (Object $inf, Object $signature) {
        
        if ($signature->isa('Template::SX::Document::Bareword')) {
            
            return +{
                rest_var    => pp($signature->value),
                has_max     => 0,
                has_min     => 0,
            };
        }
        elsif ($signature->isa('Template::SX::Document::Cell::Application')) {

            my ($rest, @positional);
            my @nodes = $signature->all_nodes;

            my $seen_dot;
            for my $node (@nodes) {

                E_SYNTAX->throw(
                    message     => 'lambda parameter list can only contain barewords',
                    location    => $node->location,
                ) unless $node->isa('Template::SX::Document::Bareword');

                if ($node->is_dot) {

                    E_SYNTAX->throw(
                        message     => 'multiple dots are illegal in lambda parameter list',
                        location    => $node->location,
                    ) if $seen_dot;

                    $seen_dot++;
                }
                else {

                    $inf->assure_unreserved_identifier($node);
                }
            }

            PARAM: while (my $param = shift @nodes) {
                
                if ($param->value eq '.') {

                    E_SYNTAX->throw(
                        message     => 'dot in lambda parameter list must be followed by one rest variable identifier',
                        location    => (@nodes < 1 ? $param->location : $nodes[1]->location),
                    ) unless @nodes == 1;

                    $rest = shift @nodes;
                    last PARAM;
                }

                push @positional, $param;
            }

            return +{
              ( $rest ? (rest_var => pp($rest->value)) : () ),
                has_min     => 1,
                has_max     => ($rest ? 0 : 1),
                min         => scalar(@positional),
                max         => scalar(@positional),
                positionals => sprintf(
                    '[%s]', join(
                        ', ',
                        map { pp($_->value) } @positional
                    ),
                ),
            };
        }
        else {

            E_SYNTAX->throw(
                message     => 'invalid lambda parameter specification',
                location    => $signature->location,
            );
        }
    }

    method make_definition (Str :$name, CodeRef :$source) {

        return sub {
            my $env = shift;

            return $env->{vars}{ $name } = $source->($env);
        };
    }

    method make_definition_scope (HashRef[CodeRef] :$vars, CodeRef :$sequence?) {

        return sub { undef }
            unless $sequence;

        return sub {
            my $env = shift;

            return $sequence->({ 
                parent  => $env, 
                vars    => { 
                    map { ($_, $vars->{ $_ }->($env)) } keys %$vars
                },
            });
        };
    }
}
