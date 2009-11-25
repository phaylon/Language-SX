use MooseX::Declare;

class Template::SX::Library::ScopeHandling extends Template::SX::Library {
    use MooseX::MultiMethods;
    use MooseX::ClassAttribute;
    use CLASS;
    use utf8;

    use TryCatch;
    use Sub::Name;
    use Sub::Call::Tail;
    use List::AllUtils              qw( all );
    use Scalar::Util                qw( blessed );
    use Data::Dump                  qw( pp );
    use Template::SX::Constants     qw( :all );
    use Template::SX::Types         qw( :all );
    use Template::SX::Util          qw( :all );
    use MooseX::Types::Structured   qw( :all );
    use Data::Alias                 qw( alias );
    Class::MOP::load_class($_)
        for E_SYNTAX, E_RESERVED, E_PROTOTYPE, E_TYPE;

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
                name    => pp($inf->collect_lexical($var->value)),
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
        CodeRef             :$setter!, 
        CodeRef             :$source!, 
        ArrayRef[CodeRef]   :$arguments!, 
        Location            :$location!, 
        Location            :$set_location!
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

    method make_variable_setter (Str :$name!, CodeRef :$source!) {

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
#        $inf->collect_lexical($variable->value);

        return $self->_render_definition(
            $inf, 
            $cell, 
            $variable, 
            $source->compile($inf, SCOPE_FUNCTIONAL),
        );
    }

    method _compile_empty_definition (Object $inf, Object $cell, Template::SX::Document::Bareword $variable) {

        $inf->assure_unreserved_identifier($variable);
#        $inf->collect_lexical($variable->value);

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
#        $inf->collect_lexical($name->value);

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

    method make_lexical_recursive_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars!, CodeRef :$sequence!) {

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

    method make_lexical_sequence_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars!, CodeRef :$sequence!) {

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

    method make_lexical_scope (ArrayRef[Tuple[Str, CodeRef]] :$vars!, CodeRef :$sequence!) {

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
        ) unless @_ >= 2;

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

        my $lex_inf  = $inf->with_new_lexical_collector;
        my $sequence = $lex_inf->render_sequence([@_]);

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_lambda_generator',
            args    => {
                sequence    => $sequence,
                has_min     => 0,
                has_max     => 1,
                max         => 0,
                inf         => '$inf',
                positionals => '[]',
                bind        => pp([$lex_inf->collected_lexicals]),
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

        my @seq     = @_;
        my $lex_inf = $inf->with_new_lexical_collector;
        my $body    = $lex_inf
            ->with_lexicals('_')
            ->with_new_escape_scope
            ->call(sub { 
                $_->render_escape_wrap(
                    $_->render_sequence([@seq]),
                );
            });

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_lambda_generator',
            args    => {
                sequence    => $body,
                bind        => pp([$lex_inf->collected_lexicals]),
                has_max     => 1,
                has_min     => 1,
                max         => 1,
                min         => 1,
                inf         => '$inf',
                positionals => '[qw( _ )]',
            },
        );
    });

    method _render_lambda_from_signature (Object $inf, Object $signature, ArrayRef[Object] $sequence) {

        my $lex_inf  = $inf->with_new_lexical_collector;

        my $deparsed = $self->deparse_signature($lex_inf, $signature);
        my @lexicals = @{ delete($deparsed->{_names}) || [] };

        my $body     = $lex_inf->with_lexicals(@lexicals)->render_sequence($sequence);

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_lambda_generator',
            args    => {
                %$deparsed,
                sequence => $body,
                inf      => '$inf',
                bind     => pp([$lex_inf->collected_lexicals]),
            },
        );
    }

#    method make_lambda_generator () {

    method make_lambda_parameter_setter ($arg, Bool :$as_list!) {

        ref($arg) ? do {
            my ($name, $args, $loc) = @$arg;

            my $opt    = $args->{options} || {};
            my $type   = $args->{type};
            my $where  = $opt->{where};
            my $traits = $opt->{is};

            if (my @unknown = grep { $_ ne 'is' and $_ ne 'where' } keys %$opt) {

                E_SYNTAX->throw(
                    message     => "unknown parameter option names for $name parameter: @unknown",
                    location    => $loc,
                );
            }

            my $test_where = defined($where) && sub {
                my $env = shift;
                my $val = shift;

                ref(my $test = $where->($env)) eq 'CODE' or E_TYPE->throw(
                    message     => "where clause argument for parameter $name must evaluated to code reference",
                    location    => $loc,
                );

                ($as_list ? (all { $test->($_) } @$val) : $test->($val)) or E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => "value for parameter $name did not pass the custom value constraint" },
                );
            };

            my $is_coerced = $traits->{coerced};

            if (my @unknown = grep { $_ ne 'coerced' } keys %{ $traits || {} }) {

                E_SYNTAX->throw(
                    message     => "unknown parameter trait names for $name parameter: @unknown",
                    location    => $loc,
                );
            }

            my $test_type = sub {
                my ($env, $val) = @_;
                my $test = $type->($env);

                blessed($test) and $test->isa('Moose::Meta::TypeConstraint') or E_TYPE->throw(
                    message     => "the type constraint specification for parameter $name does not evaluate to a type object",
                    location    => $loc,
                );

                $val = ($as_list ? [map { $test->coerce($_) } @$val] : $test->coerce($val))
                    if $is_coerced;

                ($as_list ? (all { $test->check($_) } @$val) : $test->check($val)) or E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => "value for parameter $name did not pass the $test type constraint" },
                );

                return $val;
            };

            sub {
                my ($env, $val) = @_;
                $val = $test_type->($env, $val);
                $test_where->($env, $val) if $test_where;
                $env->{vars}{ $name } = $val;
            };
        }
        : 
        sub { 

            $_[0]->{vars}{ $arg } = $_[1];
        };
    }

    method make_lambda_generator (
        Bool                    :$has_max?,
        Bool                    :$has_min?,
        CodeRef                 :$sequence!,
        Int                     :$max?,
        Int                     :$min?,
        ArrayRef                :$positionals?,
        ArrayRef[Str]           :$bind!,
        Template::SX::Inflator  :$inf!,
        Str|ArrayRef            :$rest_var?
    ) {

        my @setters  = map { $self->make_lambda_parameter_setter($_) } @$positionals;
        my $set_rest = $rest_var && $self->make_lambda_parameter_setter($rest_var, as_list => 1);

        return sub {
            my $outer_env = shift;
            my $env = {};

          BINDING:
            for my $bound (@$bind) {
#                warn "TRYING TO BIND $bound\n";

                my $search_in = $outer_env;
                while ($search_in) {
#                    warn "SEARCHING...\n";

                    if (exists $search_in->{vars}{ $bound }) {
#                        warn "FOUND!\n";
                        alias $env->{vars}{ $bound } = $search_in->{vars}{ $bound };
                        next BINDING;
                    }

                    $search_in = $search_in->{parent};
                }
#                warn "NOT FOUND!\n";
            }

#            warn "DONE BINDING: ", pp($env), "\n";

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

                my $new_env = { vars => {}, parent => $env };
                $_->($new_env, shift(@_))
                    for @setters;
                $set_rest->($new_env, [@_])
                    if $set_rest;

#                my %vars;
#                $vars{ $_ } = shift
#                    for @$positionals;

#                $vars{ $rest_var } = [@_]
#                    if $rest_var;

#                my $new_env = { vars => \%vars, parent => $env };
                tail $new_env->$sequence;
            };
        };
    }

    method deparse_signature (Template::SX::Inflator $inf, Object $signature) {
        
        if ($signature->isa('Template::SX::Document::Bareword')) {
            
            return +{
                rest_var    => pp($signature->value),
                has_max     => 0,
                has_min     => 0,
                _names      => [$signature->value],
            };
        }
        elsif ($signature->isa('Template::SX::Document::Cell::Application')) {

            my ($rest, @positional);
            my @nodes = $signature->all_nodes;

            my $seen_dot;
            for my $node (@nodes) {

#                E_SYNTAX->throw(
#                    message     => 'lambda parameter list can only contain barewords',
#                    location    => $node->location,
#                ) unless $node->isa('Template::SX::Document::Bareword');

                if ($node->isa('Template::SX::Document::Bareword') and $node->is_dot) {

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
                
                if ($param->isa('Template::SX::Document::Bareword') and $param->value eq '.') {

                    E_SYNTAX->throw(
                        message     => 'dot in lambda parameter list must be followed by one rest variable identifier',
                        location    => (@nodes < 1 ? $param->location : $nodes[1]->location),
                    ) unless @nodes == 1;

                    $rest = deparse_parameter_spec $inf, shift @nodes;
                    last PARAM;
                }

                push @positional, deparse_parameter_spec $inf, $param;
            }

            my $flatten_param = sub {
                my $param = shift;
                return pp($param) unless ref $param;
                return sprintf(
                    '[%s]',
                    join(
                        ', ',
                        pp($param->[0]),
                        sprintf(
                            '+{ type => %s, options => %s }',
                            $param->[1]{type},
                            sprintf(
                                '+{ is => %s, %s }',
                                pp($param->[1]{options}{is}),
                                join ', ', 
                                map  { sprintf('%s => %s', pp($_), $param->[1]{options}{ $_ }) }
                                grep { $_ ne 'is' }
                                keys %{ $param->[1]{options} || {} }
                            ),
                        ),
                        pp($param->[2]),
                    ),
                );
            };

            return +{
              ( $rest ? (rest_var => $flatten_param->($rest)) : () ),
                has_min     => 1,
                has_max     => ($rest ? 0 : 1),
                min         => scalar(@positional),
                max         => scalar(@positional),
                _names      => [
                    ($rest ? (ref($rest) ? $rest->[0] : $rest) : ()),
                    map { ref() ? $_->[0] : $_ } @positional,
                ],
                positionals => sprintf(
                    '[%s]', join(
                        ', ',
                        map { $flatten_param->($_) } @positional
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

    method make_definition (Str :$name!, CodeRef :$source!) {

        return sub {
            my $env = shift;

            $env->{vars}{ $name } = undef;
            return $env->{vars}{ $name } = $source->($env);
        };
    }

    method make_definition_scope (HashRef[CodeRef] :$vars!, CodeRef :$sequence?) {

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

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Library::Core
@see_also Template::SX::Library::Data::Functions
@license  Template::SX

@class Template::SX::Library::ScopeHandling

Functionality related to variable declaration, scoping and function declaration

@DESCRIPTION

=encoding utf8

This library contains all functionality related to declarations of variables, lexically
scoping variables and declaring functions (which create new scopes dynamically).

=head1 PROVIDED SYNTAX ELEMENTS

=head2 lambda

!TAG<functions>
!TAG<variables>
!TAG<arguments>

    (lambda <signature> <expr> ...)

The C<lambda> construct allows you to build anonymous functions. A simple example:

    (lambda (n) (+ n 1))

This will return a new function that takes one argument named C<n>, and executes the
C<(+ n 1)> form in a new scope with C<n> set to the passed in value. The expressions in
the body are treated as a sequence, and the last expression's return value will be
returned to the caller.

Of course you can have multiple arguments as well:

    (lambda (n m) (+ n m))

The above function takes two arguments instead of one. You can also define a so-called
rest variable, that will receive all additional arguments:

    (lambda (n . ns) "n is ${ (join ", " ns) }")

In the above setting, C<n> will contain the first passed in argument, while C<ns> will
be a list containing all other values. If there were none, the list will be empty. But
it will always be a list. Of course you can only have a single rest variable.

If you imported types via L<Template::SX::Library::Types/"import/types">, you can use them
in your signatures:

    (lambda ([Str n] . [Int ns]) ...)

!TAG<type objects>

Additionally, you can add a C<where> clause to add further constraints to the parameter:

    (lambda ([Int n where even?]) (+ n 1))

The value passed in after the C<where> bareword must evaluate to a code reference that will
be called with the argument and that must return true or false indicating whether the value
is valid or not.

If you want to receive all arguments in a list, you can simply put a bareword in the place
of the signature:

    (lambda ns (join ", " ns))

If you care about the type of the list, you can use the more word version of the above and
simply leave the part in the signature in front of the dot (C<.>) empty:

    (lambda (. [Int ns]) (join ", " ns))

All of these evaluate to regular Perl code references that can be passed to and used in Perl
space.

While you cannot L</define> a variable with the same name as a syntax construct (for
implementation reasons), you can create variables in a new scope with reserved names. This
includes function parameters. This works:

    (lambda lambda lambda)

This is a new function, that receives all its arguments in a list called C<lambda> and then
returns that list.

=head2 define

!TAG<variables>
!TAG<arguments>

    (define <variable> <value>)
    (define (<function-name> <function-signature>) <body-expr> ...)

The C<define> construct is used to declare a new variable in the current scope. It has
basically two different forms:

=over

=item *

If the C<variable> part of the definition is a bareword, C<define> will create a new variable
under that name and assign it either a value passed as second argument (C<value> above) or an
undefined value:

    (define foo 23)     ; foo is now 23
    (define foo)        ; foo is now undefined

=item *

!TAG<functions>

If the C<variable> part is a list, there are multiple possibilities. If the first item is simply
a bareword, a new function will be created with the rest of the list as signature. This function
will then be stored in the new variable:

    (define (add n m) (+ n m))
    (add 2 3)

The signature is parsed exactly as described under L</lambda>. You can use a rest variable:

    (define (foo n . ns) ...)

You can also build a signature that puts everything into the rest variable:

    (define (foo . ns) ...)

And, of course, you can use types:

    (define (foo (Int n)) (* 2 n))

But there's more to this construct: If the first element in the signature list is not a bareword
that can be used as a name, but a list instead, C<define> will automatically create a currying
generator:

    (define ((add n) m) (+ n m))

    (add 2)         ; returns a code reference expecting n
    ((add 2) 3)     ; returns 5

You can nest these generators as deep as you need:

    (define ((((add a) b) c) d) (+ a b c d))

    (define add2 (add 2))
    (define add5 (add2 3))
    (define add9 (add5 4))
    (add9 1)                    ; returns 10

In every step you can use the typical signature features like types and rest variables:

    (define ((build-join-list . [Str ls]) [Str sep])
      (join sep ls))

    (define jl (build-join-list 1 2 3))
    (jl ", ")                               ; "1, 2, 3"

This feature might seem more confusing at first than it actually is. If you look closely, 
the function definition is structured exactly the same as a call to it:

    ; declaration on top, call on bottom:
    (define (((foo x) y) z)   (+ x y z))
            (((foo 1) 2) 3) ; (+ 1 2 3) => 6

=back

Note that you cannot define a variable when a syntax element of the same name exists.

=head2 set!

!TAG<setter>

    (set! <variable> <value>)
    (set! (<setter> <setter-arg> ...) <value>)

The C<set!> construct is used to change an already existing variable. It has two different
forms:

=over

=item *

If the first argument is a bareword naming a variable, the variable will simply be set to the
value:

    (define foo 12)
    (set! foo 23)

=item *

If the first argument is a list, a runtime setter will be used to change a value. The list must
contain the name of the setter as the first item and the arguments to the setter as the rest of
the elements. The runtime value setter always takes a single argument as the variable setter:

    (set! (setter 1 2) 3)

A simple example using the L<list-ref|Template::SX::Library::Data::Lists/list-ref> setter 
would be:

    (define foo '(1 2 3))
    (set! (list-ref foo 1) 5)

There are also setters for L<list-splice|Template::SX::Library::Data::Lists/list-splice>,
L<hash-ref|Template::SX::Library::Data::Hashes/hash-ref>,
L<hash-splice|Template::SX::Library::Data::Hashes/hash-splice> and
L<values|Template::SX::Library::Data::Common/values>.

=back

A setter will always return the new C<value> specified to replace the old one.

=head2 apply!

!TAG<setter>
!TAG<application>

    (apply! <variable> <applicant>)
    (apply! (<getter/setter> <arg> ...) <applicant>)

This is a mixture construct of L</set!> and L<Template::SX::Library::Data::Functions/apply>.
Instead of taking a value as the second argument, C<apply!> takes an applicant that will
receive the current value as first argument. The return value of the applicant will then
be used as the new value. An example with a variable would look like this:

    (define foo 23)
    (apply! foo ++)     ; increase by 1

The above call to C<apply!> could be roughly translated to doing

    (set! foo (++ foo))

As with L</set!> you can use runtime setters:

    (define foo '(1 2 3))
    (apply! (list-ref foo 1) ++)

which can be read as a short form of

    (set! (list-ref foo 1) (++ (list-ref foo 1)))

The only difference is that with C<apply!> the getter/setter arguments are only evaluated 
once. So if you do

    (apply! (list-ref foo (inc-some-counter)) ++)

the C<inc-some-counter> routine will only be called once.

=head2 let

!TAG<scoping>
!TAG<variables>

    (let ((<variable> <value>) ...) <expr> ...)

You can use the C<let> construct and all its variants to create an enclosed variable scope.
A simple example to give you an idea:

    (let [(x 3)
          (y 4)]
      (+ x y))

This will execute C<(+ x y)> with C<x> set to 3 and C<y> set to 4. These values will not be
available outside of the C<let> expression. If variables of the same name have been declared
outside, they will be shadowed by the new values.

The C<value> expressions for new variables will be called in the outer environment if C<let>
is used. To explain in code:

    (let [(x 3)
          (y 4)]
      (let [(x (+ x y))     ; x being (+ 3 4)
            (y (* x y))]    ; y being (* 3 4)
        (list x y)))        ; (list (+ 3 4) (* 3 4))

While you cannot use te names of syntax elements when declaring variables with L</define>, you
can use them with all C<let> variants. This will work as expected:

    (let ((let 23)) let)    ; returns 23

=head2 let*

!TAG<scoping>
!TAG<variables>

    (let* ((<variable> <value>) ...) <expr> ...)

This syntax construct is basically the same as L</let>, except that variables are initialised
in order, and every variable can access those defined before it. An example:

    (let [(x 23)            ; x now 23
          (x (* x 2))       ; x now 46
          (x (++ x))]       ; x now 47
      x)

=head2 let-rec

!TAG<scoping>
!TAG<variables>

    (let-rec ((<variable> <value>) ...) <expr> ...)

This is basically the same as L</let>, except that all C<value> expressions will be evaluated
I<inside> the inner scope, with the variables initialised to an undefined value. This means that
I<each> variable evaluation binds to the environment that holds the final new variable. This also
means that this will work:

    (let-rec [(handle-even 
                (lambda (n . ns)
                  (if (empty? ns)
                    '(:last-was-uneven)
                    (if (not (even? n))
                      (append (list uneven: n) (apply handle-uneven ns))
                      (append (list n)         (apply handle-even ns))))))
              (handle-uneven
                (lambda (n . ns)
                  (if (empty? ns)
                    '(:last-was-uneven)
                    (if (even? n)
                      (append (list even: n) (apply handle-even ns))
                      (append (list n)       (apply handle-uneven ns))))))]
      (list (handle-even 2 4 3 5 6 8)
            (handle-uneven 2 3 4 4 3)))

and return

    ((2 4 uneven: 3 5 even: 6 :last-was-uneven)
     (even: 2 uneven: 3 even: 4 4 uneven: 3 :last-was-even))

Of course since we don't do tail call elimination, this exact case would be rather inefficient.

=head2 λ

!TAG<functions>
!TAG<shortcut>

The unicode lambda character is an alias to the L</lambda> construct.

=head2 <-

!TAG<functions>
!TAG<shortcut>

    (<- <expr> ...)

This syntax construct builds a thunk, or a code reference that doesn't take any arguments. A typical
example would be an iterator closure:

    (<- (resultset :next))

will return a function that will call C<(resultset :next)> everytime it's invoked.

=head2 ->

!TAG<functions>
!TAG<shortcut>

    (-> <expr-using-_> ...)

This is a shortcut construct for a single-argument L</lambda> expression. The argument will be available
as the lexically scoped variable C<_>. A function that doubles its argument would look like:

    (-> (* 2 _))

Note that the C<_> variable is a variable like anything else. It won't be automatically read by any part
of L<Template::SX>. The above is equivalent to

    (lambda (_) (* 2 _))

@method deparse_signature
%param $signature Document tree defining the signature.
Deparse signature into reusable static values.

@method make_definition
Build a variable definition callback

@method make_definition_scope
Mostly obsolete internal method.

@method make_lambda_generator
%param :$has_max        Set to true if the maximum value should be evaluated.
%param :$has_min        Set to true if the minimum value should be evaluated.
%param :$sequence       The body callback for the function.
%param :$max            Maximum number of arguments.
%param :$min            Minimum number of arguments.
%param :$positionals    Names of the lexical variables.
%param :$rest_var       Name of the rest variable.
Build a callback that generates a function.

@method make_lambda_parameter_setter
Internal method used to build optimized environmental setters for functions.

@method make_lexical_recursive_scope
Builds a callback executing a new scope with recursively evaluated variables like
L</let-rec>.

@method make_lexical_scope
Builds a callback executing a new scope with plain evaluated variables like normal
L</let>.

@method make_lexical_sequence_scope
Builds a callback executing a new scope with sequentially evaluated variables like
L</let*>

@method make_runtime_setter
%param :$setter         Runtime setting callback.
%param :$source         The source of the new value.
%param :$arguments      The arguments to the runtime setter.
%param :$location       The location of the C<set!>.
%param :$set_location   The location of the setter specification.
Build a runtime value setter callback.

@method make_value_scope
Build a value scope callback.

@method make_variable_setter
Builds a setter callback that changes a variable value.

=end fusion






=head1 NAME

Template::SX::Library::ScopeHandling - 
Functionality related to variable declaration, scoping and function declaration

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::ScopeHandling

=over 2

=item *

L<Template::SX::Library>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

=encoding utf8

This library contains all functionality related to declarations of variables, lexically
scoping variables and declaring functions (which create new scopes dynamically).

=head1 PROVIDED SYNTAX ELEMENTS

=head2 lambda

    (lambda <signature> <expr> ...)

The C<lambda> construct allows you to build anonymous functions. A simple example:

    (lambda (n) (+ n 1))

This will return a new function that takes one argument named C<n>, and executes the
C<(+ n 1)> form in a new scope with C<n> set to the passed in value. The expressions in
the body are treated as a sequence, and the last expression's return value will be
returned to the caller.

Of course you can have multiple arguments as well:

    (lambda (n m) (+ n m))

The above function takes two arguments instead of one. You can also define a so-called
rest variable, that will receive all additional arguments:

    (lambda (n . ns) "n is ${ (join ", " ns) }")

In the above setting, C<n> will contain the first passed in argument, while C<ns> will
be a list containing all other values. If there were none, the list will be empty. But
it will always be a list. Of course you can only have a single rest variable.

If you imported types via L<Template::SX::Library::Types/"import/types">, you can use them
in your signatures:

    (lambda ([Str n] . [Int ns]) ...)

Additionally, you can add a C<where> clause to add further constraints to the parameter:

    (lambda ([Int n where even?]) (+ n 1))

The value passed in after the C<where> bareword must evaluate to a code reference that will
be called with the argument and that must return true or false indicating whether the value
is valid or not.

If you want to receive all arguments in a list, you can simply put a bareword in the place
of the signature:

    (lambda ns (join ", " ns))

If you care about the type of the list, you can use the more word version of the above and
simply leave the part in the signature in front of the dot (C<.>) empty:

    (lambda (. [Int ns]) (join ", " ns))

All of these evaluate to regular Perl code references that can be passed to and used in Perl
space.

While you cannot L</define> a variable with the same name as a syntax construct (for
implementation reasons), you can create variables in a new scope with reserved names. This
includes function parameters. This works:

    (lambda lambda lambda)

This is a new function, that receives all its arguments in a list called C<lambda> and then
returns that list.

=head2 define

    (define <variable> <value>)
    (define (<function-name> <function-signature>) <body-expr> ...)

The C<define> construct is used to declare a new variable in the current scope. It has
basically two different forms:

=over

=item *

If the C<variable> part of the definition is a bareword, C<define> will create a new variable
under that name and assign it either a value passed as second argument (C<value> above) or an
undefined value:

    (define foo 23)     ; foo is now 23
    (define foo)        ; foo is now undefined

=item *

If the C<variable> part is a list, there are multiple possibilities. If the first item is simply
a bareword, a new function will be created with the rest of the list as signature. This function
will then be stored in the new variable:

    (define (add n m) (+ n m))
    (add 2 3)

The signature is parsed exactly as described under L</lambda>. You can use a rest variable:

    (define (foo n . ns) ...)

You can also build a signature that puts everything into the rest variable:

    (define (foo . ns) ...)

And, of course, you can use types:

    (define (foo (Int n)) (* 2 n))

But there's more to this construct: If the first element in the signature list is not a bareword
that can be used as a name, but a list instead, C<define> will automatically create a currying
generator:

    (define ((add n) m) (+ n m))

    (add 2)         ; returns a code reference expecting n
    ((add 2) 3)     ; returns 5

You can nest these generators as deep as you need:

    (define ((((add a) b) c) d) (+ a b c d))

    (define add2 (add 2))
    (define add5 (add2 3))
    (define add9 (add5 4))
    (add9 1)                    ; returns 10

In every step you can use the typical signature features like types and rest variables:

    (define ((build-join-list . [Str ls]) [Str sep])
      (join sep ls))

    (define jl (build-join-list 1 2 3))
    (jl ", ")                               ; "1, 2, 3"

This feature might seem more confusing at first than it actually is. If you look closely, 
the function definition is structured exactly the same as a call to it:

    ; declaration on top, call on bottom:
    (define (((foo x) y) z)   (+ x y z))
            (((foo 1) 2) 3) ; (+ 1 2 3) => 6

=back

Note that you cannot define a variable when a syntax element of the same name exists.

=head2 set!

    (set! <variable> <value>)
    (set! (<setter> <setter-arg> ...) <value>)

The C<set!> construct is used to change an already existing variable. It has two different
forms:

=over

=item *

If the first argument is a bareword naming a variable, the variable will simply be set to the
value:

    (define foo 12)
    (set! foo 23)

=item *

If the first argument is a list, a runtime setter will be used to change a value. The list must
contain the name of the setter as the first item and the arguments to the setter as the rest of
the elements. The runtime value setter always takes a single argument as the variable setter:

    (set! (setter 1 2) 3)

A simple example using the L<list-ref|Template::SX::Library::Data::Lists/list-ref> setter 
would be:

    (define foo '(1 2 3))
    (set! (list-ref foo 1) 5)

There are also setters for L<list-splice|Template::SX::Library::Data::Lists/list-splice>,
L<hash-ref|Template::SX::Library::Data::Hashes/hash-ref>,
L<hash-splice|Template::SX::Library::Data::Hashes/hash-splice> and
L<values|Template::SX::Library::Data::Common/values>.

=back

A setter will always return the new C<value> specified to replace the old one.

=head2 apply!

    (apply! <variable> <applicant>)
    (apply! (<getter/setter> <arg> ...) <applicant>)

This is a mixture construct of L</set!> and L<Template::SX::Library::Data::Functions/apply>.
Instead of taking a value as the second argument, C<apply!> takes an applicant that will
receive the current value as first argument. The return value of the applicant will then
be used as the new value. An example with a variable would look like this:

    (define foo 23)
    (apply! foo ++)     ; increase by 1

The above call to C<apply!> could be roughly translated to doing

    (set! foo (++ foo))

As with L</set!> you can use runtime setters:

    (define foo '(1 2 3))
    (apply! (list-ref foo 1) ++)

which can be read as a short form of

    (set! (list-ref foo 1) (++ (list-ref foo 1)))

The only difference is that with C<apply!> the getter/setter arguments are only evaluated 
once. So if you do

    (apply! (list-ref foo (inc-some-counter)) ++)

the C<inc-some-counter> routine will only be called once.

=head2 let

    (let ((<variable> <value>) ...) <expr> ...)

You can use the C<let> construct and all its variants to create an enclosed variable scope.
A simple example to give you an idea:

    (let [(x 3)
          (y 4)]
      (+ x y))

This will execute C<(+ x y)> with C<x> set to 3 and C<y> set to 4. These values will not be
available outside of the C<let> expression. If variables of the same name have been declared
outside, they will be shadowed by the new values.

The C<value> expressions for new variables will be called in the outer environment if C<let>
is used. To explain in code:

    (let [(x 3)
          (y 4)]
      (let [(x (+ x y))     ; x being (+ 3 4)
            (y (* x y))]    ; y being (* 3 4)
        (list x y)))        ; (list (+ 3 4) (* 3 4))

While you cannot use te names of syntax elements when declaring variables with L</define>, you
can use them with all C<let> variants. This will work as expected:

    (let ((let 23)) let)    ; returns 23

=head2 let*

    (let* ((<variable> <value>) ...) <expr> ...)

This syntax construct is basically the same as L</let>, except that variables are initialised
in order, and every variable can access those defined before it. An example:

    (let [(x 23)            ; x now 23
          (x (* x 2))       ; x now 46
          (x (++ x))]       ; x now 47
      x)

=head2 let-rec

    (let-rec ((<variable> <value>) ...) <expr> ...)

This is basically the same as L</let>, except that all C<value> expressions will be evaluated
I<inside> the inner scope, with the variables initialised to an undefined value. This means that
I<each> variable evaluation binds to the environment that holds the final new variable. This also
means that this will work:

    (let-rec [(handle-even 
                (lambda (n . ns)
                  (if (empty? ns)
                    '(:last-was-uneven)
                    (if (not (even? n))
                      (append (list uneven: n) (apply handle-uneven ns))
                      (append (list n)         (apply handle-even ns))))))
              (handle-uneven
                (lambda (n . ns)
                  (if (empty? ns)
                    '(:last-was-uneven)
                    (if (even? n)
                      (append (list even: n) (apply handle-even ns))
                      (append (list n)       (apply handle-uneven ns))))))]
      (list (handle-even 2 4 3 5 6 8)
            (handle-uneven 2 3 4 4 3)))

and return

    ((2 4 uneven: 3 5 even: 6 :last-was-uneven)
     (even: 2 uneven: 3 even: 4 4 uneven: 3 :last-was-even))

Of course since we don't do tail call elimination, this exact case would be rather inefficient.

=head2 λ

The unicode lambda character is an alias to the L</lambda> construct.

=head2 <-

    (<- <expr> ...)

This syntax construct builds a thunk, or a code reference that doesn't take any arguments. A typical
example would be an iterator closure:

    (<- (resultset :next))

will return a function that will call C<(resultset :next)> everytime it's invoked.

=head2 ->

    (-> <expr-using-_> ...)

This is a shortcut construct for a single-argument L</lambda> expression. The argument will be available
as the lexically scoped variable C<_>. A function that doubles its argument would look like:

    (-> (* 2 _))

Note that the C<_> variable is a variable like anything else. It won't be automatically read by any part
of L<Template::SX>. The above is equivalent to

    (lambda (_) (* 2 _))

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 deparse_signature

    ->deparse_signature(
        Template::SX::Inflator $inf,
        Object $signature
    )

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=item * Object C<$signature>

Document tree defining the signature.

=back

=back

Deparse signature into reusable static values.

=head2 make_definition

    ->make_definition(Str :$name!, CodeRef :$source!)

=over

=item * Named Parameters:

=over

=item * Str C<:$name>

=item * CodeRef C<:$source>

The source of the new value.

=back

=back

Build a variable definition callback

=head2 make_definition_scope

    ->make_definition_scope(
        HashRef[
            CodeRef
        ] :$vars!,
        CodeRef :$sequence
    )

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$sequence> (optional)

The body callback for the function.

=item * HashRef[CodeRef] C<:$vars>

=back

=back

Mostly obsolete internal method.

=head2 make_lambda_generator

    ->make_lambda_generator(
        Bool :$has_max,
        Bool :$has_min,
        CodeRef :$sequence!,
        Int :$max,
        Int :$min,
        ArrayRef :$positionals,
        ArrayRef[
            Str
        ] :$bind!,
        Template::SX::Inflator :$inf!,
        Str|ArrayRef :$rest_var
    )

=over

=item * Named Parameters:

=over

=item * ArrayRef[Str] C<:$bind>

=item * Bool C<:$has_max> (optional)

Set to true if the maximum value should be evaluated.

=item * Bool C<:$has_min> (optional)

Set to true if the minimum value should be evaluated.

=item * L<Template::SX::Inflator> C<:$inf>

=item * Int C<:$max> (optional)

Maximum number of arguments.

=item * Int C<:$min> (optional)

Minimum number of arguments.

=item * ArrayRef C<:$positionals> (optional)

Names of the lexical variables.

=item * ArrayRef|Str C<:$rest_var> (optional)

Name of the rest variable.

=item * CodeRef C<:$sequence>

The body callback for the function.

=back

=back

Build a callback that generates a function.

=head2 make_lambda_parameter_setter

    ->make_lambda_parameter_setter($arg, Bool :$as_list!)

=over

=item * Positional Parameters:

=over

=item * C<$arg>

=back

=item * Named Parameters:

=over

=item * Bool C<:$as_list>

=back

=back

Internal method used to build optimized environmental setters for functions.

=head2 make_lexical_recursive_scope

    ->make_lexical_recursive_scope(
        ArrayRef[
            Tuple[
                Str,
                CodeRef
            ]
        ] :$vars!,
        CodeRef :$sequence!
    )

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$sequence>

The body callback for the function.

=item * ArrayRef[L<Tuple|MooseX::Types::Structured/Tuple>[Str,CodeRef]] C<:$vars>

=back

=back

Builds a callback executing a new scope with recursively evaluated variables like
L</let-rec>.

=head2 make_lexical_scope

    ->make_lexical_scope(
        ArrayRef[
            Tuple[
                Str,
                CodeRef
            ]
        ] :$vars!,
        CodeRef :$sequence!
    )

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$sequence>

The body callback for the function.

=item * ArrayRef[L<Tuple|MooseX::Types::Structured/Tuple>[Str,CodeRef]] C<:$vars>

=back

=back

Builds a callback executing a new scope with plain evaluated variables like normal
L</let>.

=head2 make_lexical_sequence_scope

    ->make_lexical_sequence_scope(
        ArrayRef[
            Tuple[
                Str,
                CodeRef
            ]
        ] :$vars!,
        CodeRef :$sequence!
    )

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$sequence>

The body callback for the function.

=item * ArrayRef[L<Tuple|MooseX::Types::Structured/Tuple>[Str,CodeRef]] C<:$vars>

=back

=back

Builds a callback executing a new scope with sequentially evaluated variables like
L</let*>

=head2 make_runtime_setter

    ->make_runtime_setter(
        CodeRef :$setter!,
        CodeRef :$source!,
        ArrayRef[
            CodeRef
        ] :$arguments!,
        Location :$location!,
        Location :$set_location!
    )

=over

=item * Named Parameters:

=over

=item * ArrayRef[CodeRef] C<:$arguments>

The arguments to the runtime setter.

=item * L<Location|Template::SX::Types/Location> C<:$location>

The location of the C<set!>.

=item * L<Location|Template::SX::Types/Location> C<:$set_location>

The location of the setter specification.

=item * CodeRef C<:$setter>

Runtime setting callback.

=item * CodeRef C<:$source>

The source of the new value.

=back

=back

Build a runtime value setter callback.

=head2 make_value_scope

    ->make_value_scope(HashRef[CodeRef] :$variables!)

=over

=item * Named Parameters:

=over

=item * HashRef[CodeRef] C<:$variables>

=back

=back

Build a value scope callback.

=head2 make_variable_setter

    ->make_variable_setter(Str :$name!, CodeRef :$source!)

=over

=item * Named Parameters:

=over

=item * Str C<:$name>

=item * CodeRef C<:$source>

The source of the new value.

=back

=back

Builds a setter callback that changes a variable value.

=head2 meta

Returns the meta object for C<Template::SX::Library::ScopeHandling> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Library::Core>

=item * L<Template::SX::Library::Data::Functions>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut