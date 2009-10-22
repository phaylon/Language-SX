use MooseX::Declare;

class Template::SX::Library::ScopeHandling extends Template::SX::Library {
    use MooseX::MultiMethods;
    use MooseX::ClassAttribute;
    use CLASS;

    use Scalar::Util                qw( blessed );
    use Data::Dump                  qw( pp );
    use Template::SX::Constants     qw( :all );
    use Template::SX::Types         qw( :all );
    use MooseX::Types::Structured   qw( :all );
    Class::MOP::load_class($_)
        for E_SYNTAX, E_RESERVED;

    class_has '+function_map';
    class_has '+syntax_map';

    my $LetSyntax = sub {
        my ($name, $maker, %args) = @_;

        return sub {
            my $self = shift;
            my $inf  = shift;
            my $cell = shift;

            return $self->_render_let_scoping($inf, $cell, $name, $maker, \@_, %args);
        };
    };

    CLASS->add_syntax('let'     => $LetSyntax->('let',      'make_lexical_scope',               forbid_redefine => 1));
    CLASS->add_syntax('let*'    => $LetSyntax->('let*',     'make_lexical_sequence_scope'));
    CLASS->add_syntax('let-rec' => $LetSyntax->('let-rec',  'make_lexical_recursive_scope',     forbid_redefine => 1));

    method _render_let_scoping (Object $inf, Object $cell, Str $name, Str $maker, ArrayRef[Object] $args, Bool :$forbid_redefine) {

        my ($vars, @body) = $self->_unpack_let($name, $inf, $cell, $args, forbid_redefine => $forbid_redefine);

        return $inf->render_call(
            library => $CLASS,
            method  => $maker,
            args    => {
                vars        => $self->_render_var_spec($inf, $vars),
                sequence    => $inf->render_sequence(\@body),
            },
        );
    }

    method _render_var_spec (Object $inf, ArrayRef[Tuple[Str, Object]] $vars) {

        return sprintf(
            '[%s]', join(
                ', ',
                map { 
                    sprintf('[%s, %s]',
                        pp($_->[0]), 
                        $_->[1]->compile($inf, SCOPE_FUNCTIONAL),
                    );
                } @$vars,
            ),
        );
    }

    method _unpack_let (Str $name, Object $inf, Object $cell, ArrayRef[Object] $args, Bool :$forbid_redefine) {

        E_SYNTAX->throw(
            message     => "$name expects a variable specification and at least one body expression",
            location    => $cell->location,
        ) unless @$args == 2;

        my ($vars, @body) = @$args;

        E_SYNTAX->throw(
            message     => "variable specification for $name must be a () list",
            location    => $vars->location,
        ) unless $vars->isa('Template::SX::Document::Cell::Application');

        my @pairs = $vars->all_nodes;
        my %seen;

        return(
            [ map {
                my $pair = $pairs[ $_ ];

                E_SYNTAX->throw(
                    message     => "element $_ in variable specification is not a () list",
                    location    => $pair->location,
                ) unless $pair->isa('Template::SX::Document::Cell::Application');

                E_SYNTAX->throw(
                    message     => sprintf('element %d in variable specification is not a pair (it has %d elements)', $_, $pair->node_count),
                    location    => $pair->location,
                ) unless $pair->node_count == 2;

                my ($name, $source) = $pair->all_nodes;

                E_SYNTAX->throw(
                    message     => "variable name in element $_ of parameter specification is not a bareword",
                    location    => $name->location,
                ) unless $name->isa('Template::SX::Document::Bareword');

                E_SYNTAX->throw(
                    message     => sprintf(qq(cannot declare variable '%s' multiple times in same $name scope), $name->value),
                    location    => $name->location,
                ) if $forbid_redefine and $seen{ $name->value }++;

                [$name->value, $source];

            } 0 .. $#pairs ],
            @body,
        );
    }

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

    multi method compile_definition (Object $inf, Object $cell, Template::SX::Document::Cell::Application $sig, $first, @body) {

        my ($name, $lambda) = $self->_wrap_lambda($inf, $cell, $sig, $inf->render_sequence([$first, @body]));

        return $self->_render_definition($inf, $cell, $name, $lambda);
    }

    method _wrap_lambda (Object $inf, Object $cell, Object $sig, Str $body) {
        
        E_SYNTAX->throw(
            message     => 'lamda shortcut definition expects a name or generator spec as first item of the signature',
            location    => $sig->location,
        ) unless $sig->node_count;

        my ($name, @params) = $sig->all_nodes;
        my $param_sig = $sig->meta->clone_object($sig, nodes => \@params);

        if ($name->isa('Template::SX::Document::Cell::Application')) {

            my $wrapped_body = $self->_render_lambda_from_signature($inf, $param_sig, $body);
            return $self->_wrap_lambda($inf, $cell, $name, $wrapped_body);
        }
        elsif ($name->isa('Template::SX::Document::Bareword')) {

            return ($name->value, $self->_render_lambda_from_signature($inf, $param_sig, $body));
        }
        else {

            E_SYNTAX->throw(
                message     => 'name in signature must be bareword or generator specification',
                location    => $name->location,
            );
        }
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

    method make_lexical_recursive_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars, CodeRef :$sequence) {

        return sub {
            my $env     = shift;
            my $new_env = {
                parent  => $env,
                vars    => {
                    map { ($_->[0] => undef) } @$vars
                },
            };

            $new_env->{vars}{ $_->[0] } = $_->[1]->($new_env)
                for @$vars;

            return $sequence->($new_env);
        };
    }

    method make_lexical_sequence_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars, CodeRef :$sequence) {

        return sub {
            my $env     = shift;
            my $new_env = $env;

            for my $pair (@$vars) {
                $new_env = { 
                    parent  => $env,
                    vars    => { 
                        $pair->[0] => $pair->[1]->($env),
                    },
                };
                $env = $new_env;
            }

            return $sequence->($env);
        };
    }

    method make_lexical_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars, CodeRef :$sequence) {

        return sub {
            my $env     = shift;
            my $new_env = { 
                parent  => $env,
                vars    => { 
                    map { ($_->[0], $_->[1]->($env)) } @$vars 
                },
            };

            return $sequence->($new_env);
        };
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

        return $self->_render_lambda_from_signature($inf, $signature, $inf->render_sequence(\@body));
    });

    method _render_lambda_from_signature (Object $inf, Object $signature, Str $sequence) {

        my $deparsed = $self->deparse_signature($inf, $signature);

        $inf->render_call(
            library => $CLASS,
            method  => 'make_lambda_generator',
            args    => {
                %$deparsed,
                sequence => $sequence,
            },
        );
    }

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
