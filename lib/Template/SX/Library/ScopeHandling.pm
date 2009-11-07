use MooseX::Declare;

class Template::SX::Library::ScopeHandling extends Template::SX::Library {
    use MooseX::MultiMethods;
    use MooseX::ClassAttribute;
    use CLASS;
    use utf8;

    use TryCatch;
    use Sub::Name;
    use Sub::Call::Tail;
    use Scalar::Util                qw( blessed );
    use Data::Dump                  qw( pp );
    use Template::SX::Constants     qw( :all );
    use Template::SX::Types         qw( :all );
    use MooseX::Types::Structured   qw( :all );
    Class::MOP::load_class($_)
        for E_SYNTAX, E_RESERVED, E_PROTOTYPE;

    class_has '+function_map';
    class_has '+syntax_map';

    CLASS->add_syntax('apply!', sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        E_SYNTAX->throw(
            message     => 'apply! always expects 2 arguments, not ' . scalar(@_),
            location    => $cell->location,
        ) unless @_ == 2;

        my ($target, $applicant) = @_;

        require Template::SX::Document::Cell::Application;

        my $scope = $inf->create_value_scope;

        if ($target->isa('Template::SX::Document::Cell::Application')) {
            my ($name, @args) = $target->all_nodes;
            
            $target = $target->meta->clone_object($target, nodes => [
                $name,
                map { $scope->add_variable($_) } @args
            ]);
        }

        my $apply = Template::SX::Document::Cell::Application->new(
            location    => $applicant->location,
            nodes       => [
                $applicant,
                $target,
            ],
        );
        return $scope->wrap(
            $self->_compile_setter($inf, $cell, $target, $apply),
            $inf,
        );
    });

    method make_value_scope (HashRef[CodeRef] :$variables!) {

        my %vs_args;
        return subname VALUE_SCOPE => sub {
            my ($action, $arg) = @_;

            if ($action eq 'enclose') {

                return subname VALUE_SCOPE_CLOSURE => sub {
                    my $env = shift;

                    %vs_args = map { ($_, $variables->{ $_ }->($env)) } keys %$variables;
#                    warn "ENCLOSING " . pp(\%vs_args);
                    return $arg->($env);
                };
            }
            elsif ($action eq 'getter_for') {

                return sub { 
#                    warn "GETTING $arg = $vs_args{ $arg } " . pp(\%vs_args); 
                    $vs_args{ $arg } 
                };
            }
            else {

                E_PROTOTYPE->throw(
                    class       => E_INTERNAL,
                    attributes  => { message => "invalid scope value action '$action'" },
                );
            }
        };
    }

    CLASS->add_syntax('set!', sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        E_SYNTAX->throw(
            message     => 'set! always expects 2 arguments, not ' . scalar(@_),
            location    => $cell->location,
        ) unless @_ == 2;

        $self->_compile_setter($inf, $cell, @_);
    });

    multi method _compile_setter (Object $inf, Object $cell, Template::SX::Document::Bareword $var, Object $source) {

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_variable_setter',
            args    => {
                name    => pp($var->value),
                source  => $source->compile($inf, SCOPE_FUNCTIONAL),
            },
        );
    }

    multi method _compile_setter (Object $inf, Object $cell, Template::SX::Document::Cell::Application $special, Object $source) {

        E_SYNTAX->throw(
            message     => 'illegal empty setter specification',
            location    => $special->location,
        ) unless $special->node_count;

        my ($setter, @setter_args) = $special->all_nodes;

        E_SYNTAX->throw(
            message     => 'first item in setter specification must be a bareword naming the setter',
            location    => $setter->location,
        ) unless $setter->isa('Template::SX::Document::Bareword');

        my $library = $inf->find_library_with_setter($setter->value)
            or E_SYNTAX->throw(
                message     => sprintf(q(unknown setter '%s' in setter target specification), $setter->value),
                location    => $setter->location,
            );

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_runtime_setter',
            args    => {
                source          => $source->compile($inf, SCOPE_FUNCTIONAL),
                setter          => $inf->render_call(
                    library     => ref($library),
                    method      => 'get_setter',
                    args        => [pp($setter->value)],
                ),
                location        => pp($cell->location),
                set_location    => pp($special->location),
                arguments   => sprintf(
                    '[%s]', join(
                        ', ',
                        map { $_->compile($inf, SCOPE_FUNCTIONAL) } @setter_args
                    ),
                ),
            },
        );
    }

    method make_runtime_setter (
        CodeRef             :$setter, 
        CodeRef             :$source, 
        ArrayRef[CodeRef]   :$arguments, 
        Location            :$location, 
        Location            :$set_location
    ) {

        return subname SET_RUNTIME => sub {
            my $env = shift;
            my $val;

#            warn "TRY";
            try {
                my $cb;

#                warn "TRY";
                try {
                    $cb = $setter->(map { $_->($env) } @$arguments);
#                    warn "RES";
                }
                catch (Template::SX::Exception::Prototype $e) {
                    $e->throw_at($set_location);
                }
                catch (Any $e) {
                    die $e;
                }

                $val = $source->($env);
                $cb->($val);
#                warn "RES";
            }
            catch (Template::SX::Exception::Prototype $e) {
                $e->throw_at($location);
            }
            catch (Any $e) {
                die $e;
            }

            return $val;
        };
    }

    method make_variable_setter (Str :$name, CodeRef :$source) {

        return subname SET_VAR => sub {
            my $env = shift;

            my $search = $env;
            while ($search) {

                if (exists $search->{vars}{ $name }) {
                    return $search->{vars}{ $name } = $source->($env);
                }

                $search = $search->{parent};
            }

            E_PROTOTYPE->throw(
                class       => E_INTERNAL,
                attributes  => { message => "variable setter was unable to find an environment for variable '$name'" },
            );
        };
    }

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

        my @names = map { $_->[0] } @$vars;

        return $inf->render_call(
            library => $CLASS,
            method  => $maker,
            args    => {
                vars        => $self->_render_var_spec($inf, $vars, $maker),
                sequence    => $inf->with_lexicals(@names)->render_sequence(\@body),
            },
        );
    }

    method _render_var_spec (Object $inf, ArrayRef[Tuple[Str, Object]] $vars, Str $maker) {

        $inf = $inf->with_lexicals(map { $_->[0] } @$vars)
            if $maker eq 'make_lexical_recursive_scope';

        return sprintf(
            '[%s]', join(
                ', ',
                map { 
                    my $pair = sprintf('[%s, %s]',
                        pp($_->[0]), 
                        $_->[1]->compile($inf, SCOPE_FUNCTIONAL),
                    );
                    $inf = $inf->with_lexicals($_->[0])
                        if $maker eq 'make_lexical_sequence_scope';
                    $pair;
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
                    message     => sprintf(
                        'element %d in variable specification is not a pair (it has %d elements)', 
                        $_, 
                        $pair->node_count,
                    ),
                    location    => $pair->location,
                ) unless $pair->node_count == 2;

                my ($name, $source) = $pair->all_nodes;

                E_SYNTAX->throw(
                    message     => "variable name in element $_ of parameter specification is not a bareword",
                    location    => $name->location,
                ) unless $name->isa('Template::SX::Document::Bareword');

                E_SYNTAX->throw(
                    message     => sprintf(
                        qq(cannot declare variable '%s' multiple times in same $name scope), 
                        $name->value,
                    ),
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

        my ($target, @args) = @_;

        if ($target) {

            if ($target->isa('Template::SX::Document::Bareword')) {

                if (@args == 1) {

                    return $self->_compile_value_definition($inf, $cell, $target, @args);
                }
                elsif (@args == 0) {

                    return $self->_compile_empty_definition($inf, $cell, $target);
                }
            }
            elsif ($target->isa('Template::SX::Document::Cell::Application')) {

                return $self->_compile_lambda_definition($inf, $cell, $target, @args);
            }
        }

        $self->_throw_define_exception($inf, $cell);

        #warn "DEFINE(@_)";
        #return $self->compile_definition($inf, $cell, @_);
    });

    method _compile_value_definition (Object $inf, Object $cell, Template::SX::Document::Bareword $variable, Object $source) {

        $inf->assure_unreserved_identifier($variable);

        return $self->_render_definition(
            $inf, 
            $cell, 
            $variable, 
            $source->compile($inf, SCOPE_FUNCTIONAL),
        );
    }

    method _compile_empty_definition (Object $inf, Object $cell, Template::SX::Document::Bareword $variable) {

        $inf->assure_unreserved_identifier($variable);

        return $self->_render_definition(
            $inf,
            $cell,
            $variable,
            'sub { undef }',
        );
    }

    method _compile_lambda_definition (Object $inf, Object $cell, Template::SX::Document::Cell::Application $sig, @body) {

        my ($name, $lambda) = $self->_wrap_lambda($inf, $cell, $sig, [@body]);

        $inf->assure_unreserved_identifier($name);

        return $self->_render_definition($inf, $cell, $name, $lambda);
    }

    method _wrap_lambda (Object $inf, Object $cell, Object $sig, ArrayRef[Object] $body) {
        
        E_SYNTAX->throw(
            message     => 'lamda shortcut definition expects a name or generator spec as first item of the signature',
            location    => $sig->location,
        ) unless $sig->node_count;

        my ($name, @params) = $sig->all_nodes;
        my $param_sig = $sig->meta->clone_object($sig, nodes => \@params);

        require Template::SX::Library::ScopeHandling::Lambda;
        my $lambda = Template::SX::Library::ScopeHandling::Lambda->new(
            location    => $param_sig->location,
            body        => $body,
            signature   => $param_sig,
            library     => $self,
        );

        if ($name->isa('Template::SX::Document::Cell::Application')) {

            return $self->_wrap_lambda($inf, $cell, $name, [$lambda]);

#            my $wrapped = {

#            my $wrapped_body = $self->_render_lambda_from_signature($inf, $param_sig, $body);
#            return $self->_wrap_lambda($inf, $cell, $name, $wrapped_body);
        }
        elsif ($name->isa('Template::SX::Document::Bareword')) {

            return ($name, $lambda->compile($inf, SCOPE_FUNCTIONAL));
#            return ($name->value, $self->_render_lambda_from_signature($inf, $param_sig, $body));
        }
        else {

            E_SYNTAX->throw(
                message     => 'name in signature must be bareword or generator specification',
                location    => $name->location,
            );
        }
    }

    method _render_definition (Object $inf, Object $cell, Template::SX::Document::Bareword $name, Str $source) {

        $inf->assure_unreserved_identifier($name);

        return $inf->render_call(
            library     => $CLASS,
            method      => 'make_definition',
            args        => {
                name    => pp($name->value),
                source  => $source,
            },
        );
    }

    method make_lexical_recursive_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars, CodeRef :$sequence) {

        return subname LEX_RECURSIVE => sub {
            my $env     = shift;
            my $new_env = {
                parent  => $env,
                vars    => {
                    map { ($_->[0] => undef) } @$vars
                },
            };

            $new_env->{vars}{ $_->[0] } = $_->[1]->($new_env)
                for @$vars;

            tail $new_env->$sequence;
        };
    }

    method make_lexical_sequence_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars, CodeRef :$sequence) {

        return subname LEX_SEQUENCE => sub {
            my $env     = shift;
            my $new_env = $env;

            for my $pair (@$vars) {
                $new_env = { 
                    parent  => $env,
                    vars    => { 
                        $pair->[0] => $pair->[1]->($env),
                    },
                };
#                warn "new env ", pp($new_env);
                $env = $new_env;
            }

#            warn "calling sequence ", pp($env);
#            return $sequence->($env);
            tail $env->$sequence;
        };
    }

    method make_lexical_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars, CodeRef :$sequence) {

        return subname LEX => sub {
            my $env     = shift;
            my $new_env = { 
                parent  => $env,
                vars    => { 
                    map { ($_->[0], $_->[1]->($env)) } @$vars 
                },
            };

#            return $sequence->($new_env);
            tail $new_env->$sequence;
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

        return $self->_render_lambda_from_signature($inf, $signature, \@body);
    });

    CLASS->add_syntax('λ' => CLASS->get_syntax('lambda'));

    CLASS->add_syntax('<-' => sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        E_SYNTAX->throw(
            message     => 'thunk function shortcut (<-) expects at least one body expression',
            location    => $cell->location,
        ) unless @_;

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_lambda_generator',
            args    => {
                sequence    => $inf->render_sequence([@_]),
                has_min     => 0,
                has_max     => 1,
                max         => 0,
                positionals => '[]',
            },
        );
    });

    CLASS->add_syntax('->' => sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        E_SYNTAX->throw(
            message     => 'single argument function shortcut (->) expects at least one body expression',
            location    => $cell->location,
        ) unless @_;

        my @seq = @_;
        return $inf->render_call(
            library => $CLASS,
            method  => 'make_lambda_generator',
            args    => {
                sequence    => $inf
                                ->with_lexicals('_')
                                ->with_new_escape_scope
                                ->call(sub { 
                                    $_->render_escape_wrap(
                                        $_->render_sequence([@seq]),
                                    );
                                }),
                has_max     => 1,
                has_min     => 1,
                max         => 1,
                min         => 1,
                positionals => '[qw( _ )]',
            },
        );
    });

    method _render_lambda_from_signature (Object $inf, Object $signature, ArrayRef[Object] $sequence) {

        my $deparsed = $self->deparse_signature($inf, $signature);
        my @lexicals = @{ delete($deparsed->{_names}) || [] };

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_lambda_generator',
            args    => {
                %$deparsed,
                sequence => $inf->with_lexicals(@lexicals)->render_sequence($sequence),
            },
        );
    }

#    method make_lambda_generator () {

    method make_lambda_generator (
        Bool            :$has_max,
        Bool            :$has_min,
        CodeRef         :$sequence,
        Int             :$max?,
        Int             :$min?,
        ArrayRef[Str]   :$positionals,
        Str             :$rest_var?
    ) {

        return sub {
            my $env = shift;

            return sub {

                E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => sprintf(
                        '%s (expected %s%d, received %d)',
                        ( $has_min and $min > @_ )
                        ? ('not enough arguments',  '',                 $min, scalar(@_))
                        : ('too many arguments',    'no more than ',    $max, scalar(@_))
                    ) },
                ) if ( $has_min and $min > @_ )
                  or ( $has_max and $max < @_ );
                # FIXME throw parameter prototype exceptions
#                die "not enough arguments"  if $has_min and $min > @_;
#                die "too many arguments"    if $has_max and $max < @_;

                my %vars;
                $vars{ $_ } = shift
                    for @$positionals;

                $vars{ $rest_var } = [@_]
                    if $rest_var;

                my $new_env = { vars => \%vars, parent => $env };
                tail $new_env->$sequence;
#                return $sequence->({ vars => \%vars, parent => $env });
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

#                    $inf->assure_unreserved_identifier($node);
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
                _names      => [
                    ($rest ? $rest->value : ()),
                    map { $_->value } @positional,
                ],
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
