use MooseX::Declare;

class Template::SX::Inflator {
    with 'MooseX::Traits';

    use Template::SX;
    use Carp                        qw( croak );
    use Sub::Name                   qw( subname );
    use Sub::Call::Tail;
    use TryCatch;
    use List::AllUtils              qw( uniq );
    use Scalar::Util                qw( blessed );
    use Template::SX::Types         qw( :all );
    use Template::SX::Constants     qw( :all );
    use Template::SX::Util          qw( :all );
    use MooseX::Types::Moose        qw( ArrayRef Str Object Undef HashRef CodeRef );
    use MooseX::Types::Path::Class  qw( Dir File );
    use Data::Dump                  qw( pp );
    use Path::Class                 qw( dir file );
    use Continuation::Escape;

    BEGIN {
        if ($Template::SX::TRACK_INSTANCES) {
            require MooseX::InstanceTracking;
            MooseX::InstanceTracking->import;
        }
    }

    my $PluginNamespace = __PACKAGE__ . '::Trait';

    Class::MOP::load_class($_)
        for E_UNBOUND, E_CAPTURED, E_APPLY, E_PROTOTYPE, E_INSERT;

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
            add_library     => 'unshift',
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

    has _lexical_map => (
        is          => 'ro',
        isa         => HashRef,
        required    => 1,
        default     => sub { {} },
    );

    has document_loader => (
        is          => 'ro',
        isa         => CodeRef,
        required    => 1,
    );

    has _escape_scope => (
        is          => 'ro',
        isa         => Object,
    );

    method create_value_scope (@args) {
        require Template::SX::Inflator::ValueScope;
        return Template::SX::Inflator::ValueScope->new(@args);
    }

    method build_path_finder {

        return sub {
            my $env = shift;

            while ($env) {

                return $env->{path}
                    if $env->{path};

                $env = $env->{parent};
            }

            return undef;
        };
    }

    method build_document_loader () {
        return $self->document_loader;
    }

    method known_lexical (Str $name) {
        return $self->_lexical_map->{ $name };
    }

    method with_new_escape_scope {

        require Template::SX::Inflator::EscapeScope;
        return $self->meta->clone_object($self, 
            _escape_scope => Template::SX::Inflator::EscapeScope->new,
        );
    }

    method render_escape_wrap (Str $body) {

        return $body unless $self->_escape_scope;
        return $self->_escape_scope->wrap($self, $body);
    }

    method make_escape_scope (CodeRef :$scope!) {

        return subname ESCAPE_SCOPE => sub {
            my $env = shift;

            my $res = call_cc {
                my $escape = shift;

                [return => $scope->({ parent => $env, escape => $escape, vars => {} })];
            };

            if ($res->[0] eq 'return') {
                return $res->[1];
            }
        };
    }

    my $FindEscape;
    $FindEscape = sub {
        my ($env, $find) = @_;

        return $env->{escape} 
            if $env->{escape};

        if ($env->{parent}) {
            @_ = ($env->{parent}, $find);
            goto $find;
        }

        return undef;
    };

    method make_escape_scope_exit (Str :$type, ArrayRef[CodeRef] :$values) {

        return subname ESCAPE_EXIT => sub {
            my $env    = shift;
            my $escape = $FindEscape->($env, $FindEscape)
                or E_PROTOTYPE->throw(
                    class       => E_INTERNAL,
                    attributes  => { message => 'no escape scope found that can be exited' },
                );

            $escape->([$type, map { $_->($env) } @$values]);
        }
    }

    method call (CodeRef $cb) {
        local $_ = $self;
        return $cb->($self);
    }

    method with_lexicals (Str @lexicals) {

        return $self->meta->clone_object($self, _lexical_map => {
            %{ $self->_lexical_map },
            map { ($_, 1) } @lexicals
        });
    }

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
            } 
            grep {
                defined $_->get_value($self)
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

            return subname SYNTAX_GETTER => sub { scalar $found->get_syntax($name)->($found, @_) };
        }

        return undef;
    }

    method find_library_with_setter (Str $name) {
        
        for my $lib ($self->all_libraries) {

            if (my $found = $lib->has_setter($name)) {

                return $found;
            }
        }

        return undef;
    }

    method find_library_setter (Str $name) {
        
        my $library = $self->find_library(sub { $_->has_setter($name) })
            or return undef;

        return scalar $library->get_setter($name);
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
            '(do { require %s; %s->new(traits => %s, libraries => %s, document_loader => %s) })',
            ( __PACKAGE__ ) x 2,
           pp([ 
#                map { s/${PluginNamespace}:://; $_ }
#                map $_->name, 
#                    @{ $self->meta->roles } 
            ]),
            pp([
                map { ref } $self->all_libraries
            ]),
            '$DOC_LOADER || {}',
        );
    }

    method resolve_module_meta (ArrayRef[Object] $nodes) {

        if (@$nodes and $nodes->[0]->isa('Template::SX::Document::Cell::Application')) {
            my ($cell, @other_nodes) = @$nodes;

            if ($cell->node_count and $cell->get_node(0)->isa('Template::SX::Document::Bareword')) {
                my ($word, @rest) = $cell->all_nodes;

                if ($word->value eq 'module') {
                    require Template::SX::Inflator::ModuleMeta;

                    return (
                        \@other_nodes,
                        Template::SX::Inflator::ModuleMeta->new_from_tree(
                            arguments => [@rest],
                        ),
                    );
                }
            }
        }

        return($nodes, undef);
    }

    method compile_base (ArrayRef[Object] $nodes, Scope $start_scope) {

        ($nodes, my $meta) = $self->resolve_module_meta($nodes);

        my @arg_lex = $meta ? $meta->lexicals       : ();
        $meta       = $meta ? $meta->compile($self) : '';

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
                    '(do { %s; my $root = %s; %s })',
                    $meta,
                    $self->render_call(
                        method  => 'make_sequence',
                        args    => {
                            elements    => sprintf(
                                '[%s]',
                                join(', ',
                                    $self->with_lexicals(@arg_lex)->compile_sequence($nodes, $start_scope),
                                ),
                            ),
                        },
                    ),
                    '$inf->make_root(sequence => $root)'

#                    '(do { my $root = %s; Sub::Name::subname q(ENTER_SX), sub { $root->({ vars => (@_ == 1 ? $_[0] : +{ @_ }) }) } })',
                ),
            ),
        );
        
        return $compiled;
    }

    method make_root (CodeRef :$sequence) {

        my $arg_spec = $Template::SX::MODULE_META->{arguments};
        my %required = $arg_spec ? %{ $arg_spec->{required} || {} } : ();
        my %optional = $arg_spec ? %{ $arg_spec->{optional} || {} } : ();
#        pp $arg_spec;

        my $throw = sub { 
            my ($exc, $msg) = @_;
            E_PROTOTYPE->throw(class => $exc, attributes => { message => $msg });
        };

        return subname ENTER_SX => sub {
            my %args = @_;
            my $vars = $args{vars} || {};

            if ($arg_spec) {

                exists($vars->{ $_ }) or $throw->(E_PARAMETER, "missing module argument '$_'")
                    for keys %required;

                exists($optional{ $_ }) or exists($required{ $_ }) or $throw->(E_PARAMETER, "unknown module argument '$_'")
                    for keys %$vars;

                exists($vars->{ $_ }) or $vars->{ $_ } = undef
                    for keys %optional;
            }

            my $args = \%args;
            tail $args->$sequence;
#            return scalar $sequence->(\%args);
        };
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
                    elsif ($compiled->isa('Template::SX::Inflator::Accessor')) {

                        push @compiled, $compiled->render_getter;
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

    method render_call (Str :$method, HashRef[Str] | ArrayRef[Str] :$args, Str :$library?) {

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
                ( ref $args eq 'HASH' )
                ? ( map {
                        join(' => ', pp($_), $args->{ $_ })
                    } keys %$args
                  ) 
                : @$args
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

    method make_structure_builder (ArrayRef[CodeRef] :$values, CodeRef :$template) {

        return subname STRUCTURE => sub {
            my $env = shift;
            @_ = map { [( $_->($env) )] } @$values;
            goto $template;
#            return $template->(map { [( $_->($env) )] } @$values);
        };
    }

    method make_sequence (ArrayRef[CodeRef] :$elements) {

        return subname SEQUENCE => sub {
            my $env = shift;
            
            return undef 
                unless @$elements;

            my $tail = $elements->[-1];
            $_->($env) for @{ $elements }[0 .. ($#$elements - 1)];

            tail $env->$tail;

#            my @res;

#            push @res, $_->($env)
#                for @$elements;

#            return $res[-1];
        };
    }

    method make_list_builder (ArrayRef[CodeRef] :$items, :$env) {

        return subname LIST_BUILDER => sub { 
            my $env = shift;
            return [ map { ($_->($env)) } @$items ];
        };
    }

    method make_hash_builder (ArrayRef[CodeRef] :$items) {

        return subname HASH_BUILDER => sub {
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
            return subname CACHED_OBJECT_BUILDER => sub { $cached };
        }
        else {
            return subname OBJECT_BUILDER => sub { $class->new($arguments) };
        }
    }

    method make_concatenation (ArrayRef[CodeRef] :$elements) {

        return subname CONCAT => sub {
            my $env = shift;

            return join '', map $_->($env), @$elements;
        };
    }

    method make_constant (Any :$value) {

        return subname CONSTANT => sub { $value };
    }

    method make_boolean_constant (Any :$value) {

        return $self->make_constant(value => $value);
    }

    method make_keyword_constant (Any :$value) {

        return $self->make_constant(value => $value);
    }

    method make_regex_constant (RegexpRef :$value) {

        return $self->make_constant(value => $value);
    }

    method _build_shadow_call (Location $loc) {

        return eval join "\n",
            'Sub::Name::subname q(APPLY), sub { my $op = shift;',
                sprintf('#line %d "%s"', $loc->{line}, $loc->{source}),
                'return $op->(@_);',
            '}';
    }

    method make_application (CodeRef :$apply, ArrayRef[CodeRef] :$arguments, HashRef :$location, :$env) {

        my $shadow_call = $self->_build_shadow_call($location);

        return subname APPLICATION => sub {
            my $env = shift;
            my $result;

            local $Template::SX::SHADOW_CALL = $shadow_call;

#            warn "TRY";
            try {
                $result = apply_scalar 
                    apply       => $apply->($env), 
                    arguments   => [map { $_->($env) } @$arguments];

#                warn "RES";
            }
            catch (Template::SX::Exception::Prototype $e) {
                $e->throw_at($location);
            }
            catch (Any $e) {
                die $e;
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

            @_ = ($env->{parent});
            goto $exists;
#            return $exists->($env->{parent});
        };

        my $found_env;

        return subname GETTER => sub {
            my $env = shift;
#            pp "GET $name ", $env;

            if (my $found_env = $exists->($env)) {
                return $found_env->{vars}{ $name };
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
