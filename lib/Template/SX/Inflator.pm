use MooseX::Declare;

class Template::SX::Inflator {
    with 'MooseX::Traits';

    use TryCatch;
    use List::AllUtils          qw( uniq );
    use Scalar::Util            qw( blessed );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use MooseX::Types::Moose    qw( ArrayRef Str Object Undef HashRef );
    use Data::Dump              qw( pp );

    my $PluginNamespace = __PACKAGE__ . '::Trait';

    Class::MOP::load_class($_)
        for E_UNBOUND, E_CAPTURED, E_APPLY;

    has libraries => (
        traits      => [qw( Array )],
        isa         => LibraryList,
        coerce      => 1,
        required    => 1,
        default     => sub { [] },
        handles     => {
            all_libraries   => 'elements',
            find_library    => 'first',
            map_libraries   => 'map',
        },
        init_arg    => 'libraries',
    );

    has _object_cache => (
        is          => 'ro',
        isa         => HashRef,
        required    => 1,
        default     => sub { +{} },
    );

    has '+_trait_namespace' => (
        default     => $PluginNamespace,
    );

    method new_with_resolved_traits (ClassName $class: @args) {
        my $self = $class->new_with_traits(@args);

        my @traits = uniq $self->map_libraries(sub { ($_->additional_inflator_traits) });

        return $self->clone_with_additional_traits(\@traits);
    }

    method clone_with_additional_traits (ArrayRef[Str] $traits) {

        my @roles = 
            map  { s/\A${PluginNamespace}::// }
            grep { /\A$PluginNamespace/ }
            map  { $_->name }
                @{ $self->meta->roles };

        return blessed($self)->new_with_traits(
            traits => [@$traits, @roles],
            map {
                $_->init_arg
                ? ($_->init_arg, $_->get_value($self))
                : ()
            } $self->meta->get_all_attributes,
        );
    }

    method find_library_function (Str $name) {
        
        my $library = $self->find_library(sub { $_->has_function($name) })
            or return undef;

        return scalar $library->get_functions($name);
    }

    method find_library_with_syntax (Str $name) {
        
        for my $lib ($self->all_libraries) {

            if (my $found = $lib->has_syntax($name)) {

                return $found;
            }
        }

        return undef;
    }

    method find_library_syntax (Str $name) {

        if (my $found = $self->find_library_with_syntax($name)) {

            return sub { scalar $found->get_syntax($name)->($found, @_) };
        }

        return undef;
    }

    method library_by_name (Str $libname) {

        Class::MOP::load_class($libname);
        return $libname->new;
    }

    method assure_unreserved_identifier (Template::SX::Document::Bareword $identifier) {

        if (my $lib = $self->find_library_with_syntax($identifier->value)) {

            E_RESERVED->throw(
                location    => $identifier->location,
                library     => blessed($lib),
                identifier  => $identifier->value,
                message     => sprintf(
                    q(identifier '%s' is reserved and declared as syntax in %s),
                    $identifier->value,
                    blessed($lib),
                ),
            );
        }

        return 1;
    }

    method serialize {

        return sprintf(
            '(do { require %s; %s->new(traits => %s, libraries => %s) })',
            ( __PACKAGE__ ) x 2,
           pp([ 
#                map { s/${PluginNamespace}:://; $_ }
#                map $_->name, 
#                    @{ $self->meta->roles } 
            ]),
            pp([
                map { ref } $self->all_libraries
            ]),
        );
    }

    method compile_base (ArrayRef[Object] $nodes, Scope $start_scope) {
        
        my $compiled = sprintf(
            '(do { %s })',
            join(';',

                # the inflator
                sprintf(
                    'my $inf = %s',
                    $self->serialize,
                ),

                # the nodes
                sprintf(
                    '(do { my $root = %s; sub { $root->({ vars => { @_ }}) } })',
                    $self->render_call(
                        method  => 'make_sequence',
                        args    => {
                            elements    => sprintf(
                                '[%s]',
                                join(', ',
                                    $self->compile_sequence($nodes, $start_scope),
                                ),
                            ),
                        },
                    ),
                ),
            ),
        );
        
        return $compiled;
    }

    method compile_sequence (ArrayRef[Object] $nodes, Scope $scope?) {

        my @compiled;

        if ($scope and $scope ne SCOPE_FUNCTIONAL) {

            @compiled = map { $_->compile($self, $scope) } @$nodes;
        }
        else {

            NODE: for my $node_idx (0 .. $#$nodes) {
                my $node = $nodes->[ $node_idx ];

                my $compiled = $node->compile($self, SCOPE_FUNCTIONAL);

                if (is_Object($compiled)) {

                    if ($compiled->DOES('Template::SX::Inflator::ImplicitScoping')) {

                        push @compiled, $compiled->compile_scoped($self, [@{ $nodes }[$node_idx + 1 .. $#$nodes]]);
                        last NODE;
                    }
                    else {

                        # FIXME throw exception
                        die "Unknown compiled item: $compiled";
                    }
                }
                else {

                    push @compiled, $compiled;
                }
            }
        }

        return @compiled;
    }

    method render_call (Str :$method, HashRef[Str] :$args, Str :$library?) {

        return sprintf(
            '$inf->%s(%s)',
            ( $library
                ? sprintf(
                    'library_by_name(%s)->%s',
                    pp($library),
                    $method,
                  )
                : $method
            ),
            join(', ',
                map {
                    join(' => ', pp($_), $args->{ $_ })
                } keys %$args
            ),
        );
    }

    method render_sequence (ArrayRef[Object] $sequence) {

        return $self->render_call(
            method  => 'make_sequence',
            args    => {
                elements    => sprintf(
                    '[%s]', join(
                        ', ',
                        $self->compile_sequence($sequence),
                    ),
                ),
            },
        );
    }

    method make_sequence (ArrayRef[CodeRef] :$elements) {

        return sub {
            my $env = shift;
            
            return undef 
                unless @$elements;

            my @res;

            push @res, $_->($env)
                for @$elements;

            return $res[-1];
        };
    }

    method make_list_builder (ArrayRef[CodeRef] :$items, :$env) {

        return sub { 
            my $env = shift;
            return [ map { ($_->($env)) } @$items ];
        };
    }

    method make_hash_builder (ArrayRef[CodeRef] :$items) {

        return sub {
            my $env = shift;
            return +{ map { ($_->($env)) } @$items };
        };
    }

    method make_object_builder (Str :$class, HashRef :$arguments, Str :$cached_by?) {
        Class::MOP::load_class($class);

        # many runtime objects are ro and can be cached for better performance
        if ($cached_by) {
            my $cached = $self->_object_cache->{ $class }{ $arguments->{ $cached_by } } 
                     ||= $class->new($arguments);
            return sub { $cached };
        }
        else {
            return sub { $class->new($arguments) };
        }
    }

    method make_concatenation (ArrayRef[CodeRef] :$elements) {

        return sub {
            my $env = shift;

            return join '', map $_->($env), @$elements;
        };
    }

    method make_constant (Any :$value) {

        return sub { $value };
    }

    method make_boolean_constant (Any :$value) {

        return $self->make_constant(value => $value);
    }

    method make_keyword_constant (Any :$value) {

        return $self->make_constant(value => $value);
    }

    method make_application (CodeRef :$apply, ArrayRef[CodeRef] :$arguments, HashRef :$location, :$env) {

        return sub {
            my $env = shift;
            my $evaluated_apply = $apply->($env);
            my @evaluated_args  = map { scalar $_->($env) } @$arguments;

            my $result;
            try {

                if (my $class = blessed($evaluated_apply)) {
                    
                    E_APPLY->throw(
                        message     => "missing method argument for method call on $class instance",
                        location    => $location,
                    ) unless @evaluated_args;

                    my $method = shift @evaluated_args;
                    $result = scalar $evaluated_apply->$method(@evaluated_args);
                }
                elsif (ref $evaluated_apply eq 'CODE') {

                    $result = scalar $evaluated_apply->(map { $_->($env) } @$arguments);
                }
                else {

                    E_APPLY->throw(
                        message     => 'invalid applicant type: ' . ref($evaluated_apply),
                        location    => $location,
                    );
                }
            } 
            catch (Template::SX::Exception $e) {
                die $e;
            }
            catch (Any $e) {
                E_CAPTURED->throw(
                    message     => "error during application: $e",
                    location    => $location,
                    captured    => $e,
                );
            }

            return $result;
        };
    }

    method make_getter (Str :$name, Location :$location) {

        my $lib_function = $self->find_library_function($name);

        my $exists;
        $exists = sub {
            my $env = shift;
            return $env  if exists $env->{vars}{ $name };
            return undef unless exists $env->{parent};
            return $exists->($env->{parent});
        };

        return sub {
            my $env = shift;

            if (my $found = $exists->($env)) {
                return $found->{vars}{ $name };
            }
            elsif ($lib_function) {
                return $lib_function;
            }
            else {
                E_UNBOUND->throw(
                    location        => $location,
                    message         => "unbound variable '$name' not found in environment",
                    variable_name   => $name,
                );
            }
        };
    }
}
