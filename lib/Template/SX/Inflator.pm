use MooseX::Declare;

class Template::SX::Inflator {
    with 'MooseX::Traits';

    use Template::SX::Types  qw( :all );
    use MooseX::Types::Moose qw( ArrayRef Str );
    use Data::Dump           qw( pp );

    my $PluginNamespace = __PACKAGE__ . '::Plugin';

    has libraries => (
        traits      => [qw( Array )],
        isa         => LibraryList,
        coerce      => 1,
        required    => 1,
        default     => sub { [] },
        handles     => {
            all_libraries   => 'elements',
            find_library    => 'first',
        },
    );

    has '+_trait_namespace' => (
        default     => $PluginNamespace,
    );

    method find_library_function (Str $name) {
        
        my $library = $self->find_library(sub { $_->has_function($name) })
            or return undef;

        return scalar $library->get_functions($name);
    }

    method serialize {

        return sprintf(
            '(do { require %s; %s->new(traits => %s, libraries => %s) })',
            ( __PACKAGE__ ) x 2,
            pp([ 
                map { s/${PluginNamespace}:://; $_ }
                map $_->name, 
                    @{ $self->meta->roles } 
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
                                    map {
                                        $_->compile($self, $start_scope);
                                    } @$nodes
                                ),
                            ),
                        },
                    ),
                ),
            ),
        );
        
        return $compiled;
    }

    method render_call (Str :$method, HashRef[Str] :$args) {

        return sprintf(
            '$inf->%s(%s)',
            $method,
            join(', ',
                map {
                    join(' => ', pp($_), $args->{ $_ })
                } keys %$args
            ),
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

    method make_constant (Value :$value) {

        return sub { $value };
    }

    method make_application (CodeRef :$apply, ArrayRef[CodeRef] :$arguments, :$env) {

        return sub {
            my $env = shift;
            my $evaluated_apply = $apply->($env);
            return scalar $evaluated_apply->(map { $_->($env) } @$arguments);
        };
    }

    method make_getter (Str :$name) {

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
                # FIXME throw exception
                die "Unbound variable: $name\n";
            }
        };
    }
}
