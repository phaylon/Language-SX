use MooseX::Declare;

class Language::SX::Inflator {
    with 'MooseX::Traits';

    use Language::SX;
    use Carp                        qw( croak );
    use Sub::Name                   qw( subname );
    use Sub::Call::Tail;
    use TryCatch;
    use List::AllUtils              qw( uniq );
    use Scalar::Util                qw( blessed );
    use Language::SX::Types         qw( :all );
    use Language::SX::Constants     qw( :all );
    use Language::SX::Util          qw( :all );
    use MooseX::Types::Moose        qw( ArrayRef Str Object Undef HashRef CodeRef );
    use MooseX::Types::Path::Class  qw( Dir File );
    use Data::Dump                  qw( pp );
    use Path::Class                 qw( dir file );
    use Continuation::Escape;

    BEGIN {
        if ($Language::SX::TRACK_INSTANCES) {
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

    has _lexical_collector => (
        is          => 'ro',
        isa         => Object,
    );

    has _bound_lexical_map => (
        is          => 'ro',
        isa         => HashRef,
        required    => 1,
        default     => sub { {} },
    );

    method create_value_scope (@args) {
        require Language::SX::Inflator::ValueScope;
        return Language::SX::Inflator::ValueScope->new(@args);
    }

    method build_path_finder () {

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

    method lexical_known_in_current_binding (Str $name) {
        return $self->_bound_lexical_map->{ $name };
    }

    method with_new_lexical_collector () {

        require Language::SX::Inflator::LexicalCollector;
        return $self->meta->clone_object($self,
            _bound_lexical_map  => {},
            _lexical_collector  => Language::SX::Inflator::LexicalCollector->new(
              ( $self->_lexical_collector ? (parent => $self->_lexical_collector) : () )
            ),
        );
    }

    method collected_lexicals () {

        return $self->_lexical_collector->all_lexicals;
    }

    method collect_lexical (Str $lex) {

        return $lex unless $self->_lexical_collector;
        return $lex if $self->lexical_known_in_current_binding($lex);
        $self->_lexical_collector->add_lexical($lex);
        return $lex;
    }

    method with_new_escape_scope () {

        require Language::SX::Inflator::EscapeScope;
        return $self->meta->clone_object($self, 
            _escape_scope => Language::SX::Inflator::EscapeScope->new,
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

    method make_escape_scope_exit (Str :$type!, ArrayRef[CodeRef] :$values!) {

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
        
        my %fresh = map { ($_, 1) } @lexicals;

        return $self->meta->clone_object($self, 
            _lexical_map => {
                %{ $self->_lexical_map },
                %fresh,
            },
            _bound_lexical_map => {
                %{ $self->_bound_lexical_map },
                %fresh,
            },
        );
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

    method assure_unreserved_identifier (Language::SX::Document::Bareword $identifier) {

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

    method serialize () {

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

        if (@$nodes and $nodes->[0]->isa('Language::SX::Document::Cell::Application')) {
            my ($cell, @other_nodes) = @$nodes;

            if ($cell->node_count and $cell->get_node(0)->isa('Language::SX::Document::Bareword')) {
                my ($word, @rest) = $cell->all_nodes;

                if ($word->value eq 'module') {
                    require Language::SX::Inflator::ModuleMeta;

                    return (
                        \@other_nodes,
                        Language::SX::Inflator::ModuleMeta->new_from_tree(
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

    method make_root (CodeRef :$sequence!) {

        my $arg_spec = $Language::SX::MODULE_META->{arguments};
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

                    if ($compiled->DOES('Language::SX::Inflator::ImplicitScoping')) {

                        push @compiled, $compiled->compile_scoped($self, [@{ $nodes }[$node_idx + 1 .. $#$nodes]]);
                        last NODE;
                    }
                    elsif ($compiled->isa('Language::SX::Inflator::Accessor')) {

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

    method render_call (Str :$method!, HashRef[Str] | ArrayRef[Str] :$args!, Str :$library?) {

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

    method make_structure_builder (ArrayRef[CodeRef] :$values!, CodeRef :$template!) {

        return subname STRUCTURE => sub {
            my $env = shift;
            @_ = map { [( $_->($env) )] } @$values;
            goto $template;
#            return $template->(map { [( $_->($env) )] } @$values);
        };
    }

    method make_sequence (ArrayRef[CodeRef] :$elements!) {

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

    method make_list_builder (ArrayRef[CodeRef] :$items!) {

        return subname LIST_BUILDER => sub { 
            my $env = shift;
            return [ map { ($_->($env)) } @$items ];
        };
    }

    method make_hash_builder (ArrayRef[CodeRef] :$items!) {

        return subname HASH_BUILDER => sub {
            my $env = shift;
            return +{ map { ($_->($env)) } @$items };
        };
    }

    method make_object_builder (Str :$class!, HashRef :$arguments!, Str :$cached_by?) {
        Class::MOP::load_class($class);

        # many runtime objects are ro and can be cached for better performance
        if ($cached_by) {
            warn "CACHED $class\n";
            my $cached = $self->_object_cache->{ $class }{ $arguments->{ $cached_by } } 
                     ||= $class->new($arguments);
            return subname CACHED_OBJECT_BUILDER => sub { $cached };
        }
        else {
            warn "UNCACHED $class\n";
            return subname OBJECT_BUILDER => sub { $class->new($arguments) };
        }
    }

    method make_concatenation (ArrayRef[CodeRef] :$elements!) {

        return subname CONCAT => sub {
            my $env = shift;

            return join '', map $_->($env), @$elements;
        };
    }

    method make_constant (Any :$value!) {

        return subname CONSTANT => sub { $value };
    }

    method make_boolean_constant (Any :$value!) {

        return $self->make_constant(value => $value);
    }

    method make_keyword_constant (Any :$value!) {

        return $self->make_constant(value => $value);
    }

    method make_regex_constant (RegexpRef :$value!) {

        return $self->make_constant(value => $value);
    }

    method _build_shadow_call (Location $loc) {

        return eval join "\n",
            'Sub::Name::subname q(APPLY), sub { my $op = shift;',
                sprintf('#line %d "%s"', $loc->{line}, $loc->{source}),
                'return $op->(@_);',
            '}';
    }

    method make_application (CodeRef :$apply!, ArrayRef[CodeRef] :$arguments!, HashRef :$location!) {

        my $shadow_call = $self->_build_shadow_call($location);

        return subname APPLICATION => sub {
            my $env = shift;
            my $result;

            local $Language::SX::SHADOW_CALL = $shadow_call;

#            warn "TRY";
            try {
                $result = apply_scalar 
                    apply       => $apply->($env), 
                    arguments   => [map { $_->($env) } @$arguments];

#                warn "RES";
            }
            catch (Language::SX::Exception::Prototype $e) {
                $e->throw_at($location);
            }
            catch (Any $e) {
                die $e;
            }

            return $result;
        };
    }

    method make_getter (Str :$name!, Location :$location!) {

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

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Document
@license  Language::SX

@class Language::SX::Inflator
Compiling and inflating a document to a callback tree

@method add_library
Adds a library object.

@method all_libraries
Returns a list of all libraries.

@method assure_unreserved_identifier
%param $identifier The bareword that contains the identifier name.
Throws an L<Language::SX::Exception::Reserved> if the identifier is reserved.

@method build_document_loader
Builder for callback to load further documents. Currently only returns L</document_loader>.

@method build_path_filder
Builder for callback to locate a path in the environment.

@method call
Will call C<$cb> with the inflator object in C<$_>.

@method clone_with_additional_traits
Creates a cloned object with the additional traits applied.

@method compile_base
%param $nodes Root nodes.
Compiles code for the document root sequence.

@method compile_sequence
Compiles the C<$nodes> as a sequence that will return the last items value.

@method create_value_scope
%param @args Arguments for the L<Language::SX::Inflator::ValueScope> object.
Creates a new value scope object for pre-evaluated values.

@method find_library
Takes a callback that should return true on the right library.

@method find_library_function
Tries to locate a function in the loaded libraries.

@method find_library_setter
Tries to locate a setter in the loaded libraries.

@method find_library_syntax
Tries to locate a syntax element in the loaded libraries.

@method find_library_with_setter
Returns the library that contains the setter.

@method find_library_with_syntax
Returns the library that contains the syntax element.

@method known_lexical
Test if a variable has been declared as a lexical during compile-time.

@method library_by_name
Runtime method to load a library object.

@method make_application
%param :$apply      The callback returning the applicant.
%param :$arguments  List of callbacks returning the arguments.
%param :$location   Location of the generated application.
Generates a functional application callback.

@method make_boolean_constant
Builds a callback returning a constant boolean.

@method make_concatenation
%param :$elements Callbacks returning values to concatenate.
Builds a callback returning a string of the values joined together without a separator.

@method make_constant
Universal constant callback builder.

@method make_escape_scope
Internal method.

@method make_escape_scope_exit
Internal method.

@method make_getter
%param :$location The location of the variable access.
%param :$name     The name of the variable to get.
Builds a callback to fetch a value from the environment.

@method make_hash_builder
%param :$items Even list of callbacks returning keys and values.
Builds a hash reference builder callback.

@method make_keyword_constant
Builds a callback for constant keywords.

@method make_object_builder
%param :$arguments The constructor arguments.
%param :$cached_by Name of the field in C<$arguments> that holds the cache key.
%param :$class     The class to instantiate.
Creates an (optionally cached) object creation callback.

@method make_regex_constant
Builds a callback for regular expression constants.

@method make_root
Builds a callback to wrap the root sequence with the necessary input logic.

@method make_sequence
Builds a callback that will evaluate all C<$elements> callbacks in turn and return
the value of the last element.

@method make_structure_builder
%param :$template A code reference called with the values that go into the structure.
%param :$values   Callbacks returning the values to put in the structural template.
Builds a data structure by weaving the C<$values> into the C<$template>.

@method map_libraries
C<map> for the libraries.

@method new_with_resolved_traits
Internal method for runtime inflation.

@method render_call
%param :$args       Arguments for the method call. Either positional or named.
%param :$library    Library name if C<$method> is a library method.
%param :$method     Method name to call.
Render a call to an inflator or library method.

@method render_escape_wrap
Internal method.

@method render_sequence
Renders code for a sequence iterator out of document items.

@method resolve_module_meta
Takes a list of nodes and returns an array reference of rest nodes plus an optional
L<Language::SX::Inflator::ModuleMeta> object if a C<module> directive was encountered
as first element.

@methos serialize
Renders runtime reinflation of the inflator object.

@method with_lexicals
Create a new inflator with additional known lexicals.

@method with_new_escape_scope
Internal method.

@attr document_loader
Callback to load a new document.

@attr libraries
List of loaded library objects.

@DESCRIPTION
This module handles the compilation and runtime inflation phase by providing a syntax tree with
a way to render code that builds a corresponding runtime callback tree.

=end fusion






=head1 NAME

Language::SX::Inflator - Compiling and inflating a document to a callback tree

=head1 INHERITANCE

=over 2

=item *

Language::SX::Inflator

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<MooseX::Traits>

=back

=head1 DESCRIPTION

This module handles the compilation and runtime inflation phase by providing a syntax tree with
a way to render code that builds a corresponding runtime callback tree.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * document_loader (B<required>)

Initial value for the L<document_loader|/"document_loader (required)"> attribute.

=item * libraries (optional)

Initial value for the L<libraries|/"libraries (required)"> attribute.

=back

=head2 add_library

Delegation to a generated L<unshift|Moose::Meta::Attribute::Native::MethodProvider::Array/unshift> method for the L<libraries|/libraries (required)> attribute.

Adds a library object.

=head2 all_libraries

Delegation to a generated L<elements|Moose::Meta::Attribute::Native::MethodProvider::Array/elements> method for the L<libraries|/libraries (required)> attribute.

Returns a list of all libraries.

=head2 assure_unreserved_identifier

    ->assure_unreserved_identifier(
        Language::SX::Document::Bareword $identifier
    )

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Document::Bareword> C<$identifier>

The bareword that contains the identifier name.

=back

=back

Throws an L<Language::SX::Exception::Reserved> if the identifier is reserved.

=head2 build_document_loader

    ->build_document_loader()

=over

=back

Builder for callback to load further documents. Currently only returns L</document_loader>.

=head2 build_path_finder

    ->build_path_finder()

=over

=back

=head2 call

    ->call(CodeRef $cb)

=over

=item * Positional Parameters:

=over

=item * CodeRef C<$cb>

=back

=back

Will call C<$cb> with the inflator object in C<$_>.

=head2 clone_with_additional_traits

    ->clone_with_additional_traits(ArrayRef[Str] $traits)

=over

=item * Positional Parameters:

=over

=item * ArrayRef[Str] C<$traits>

=back

=back

Creates a cloned object with the additional traits applied.

=head2 collect_lexical

    ->collect_lexical(Str $lex)

=over

=item * Positional Parameters:

=over

=item * Str C<$lex>

=back

=back

=head2 collected_lexicals

    ->collected_lexicals()

=over

=back

=head2 compile_base

    ->compile_base(ArrayRef[Object] $nodes, Scope $start_scope)

=over

=item * Positional Parameters:

=over

=item * ArrayRef[Object] C<$nodes>

Root nodes.

=item * L<Scope|Language::SX::Types/Scope> C<$start_scope>

=back

=back

Compiles code for the document root sequence.

=head2 compile_sequence

    ->compile_sequence(ArrayRef[Object] $nodes, Scope $scope?)

=over

=item * Positional Parameters:

=over

=item * ArrayRef[Object] C<$nodes>

Root nodes.

=item * L<Scope|Language::SX::Types/Scope> C<$scope> (optional)

=back

=back

Compiles the C<$nodes> as a sequence that will return the last items value.

=head2 create_value_scope

    ->create_value_scope(@args)

=over

=item * Positional Parameters:

=over

=item * C<@args>

Arguments for the L<Language::SX::Inflator::ValueScope> object.

=back

=back

Creates a new value scope object for pre-evaluated values.

=head2 document_loader

Reader for the L<document_loader|/"document_loader (required)"> attribute.

=head2 find_library

Delegation to a generated L<first|Moose::Meta::Attribute::Native::MethodProvider::Array/first> method for the L<libraries|/libraries (required)> attribute.

Takes a callback that should return true on the right library.

=head2 find_library_function

    ->find_library_function(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Tries to locate a function in the loaded libraries.

=head2 find_library_setter

    ->find_library_setter(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Tries to locate a setter in the loaded libraries.

=head2 find_library_syntax

    ->find_library_syntax(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Tries to locate a syntax element in the loaded libraries.

=head2 find_library_with_setter

    ->find_library_with_setter(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Returns the library that contains the setter.

=head2 find_library_with_syntax

    ->find_library_with_syntax(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Returns the library that contains the syntax element.

=head2 known_lexical

    ->known_lexical(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Test if a variable has been declared as a lexical during compile-time.

=head2 lexical_known_in_current_binding

    ->lexical_known_in_current_binding(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

=head2 library_by_name

    ->library_by_name(Str $libname)

=over

=item * Positional Parameters:

=over

=item * Str C<$libname>

=back

=back

Runtime method to load a library object.

=head2 make_application

    ->make_application(
        CodeRef :$apply!,
        ArrayRef[
            CodeRef
        ] :$arguments!,
        HashRef :$location!
    )

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$apply>

The callback returning the applicant.

=item * ArrayRef[CodeRef] C<:$arguments>

The constructor arguments.

=item * HashRef C<:$location>

The location of the variable access.

=back

=back

Generates a functional application callback.

=head2 make_boolean_constant

    ->make_boolean_constant(Any :$value!)

=over

=item * Named Parameters:

=over

=item * Any C<:$value>

=back

=back

Builds a callback returning a constant boolean.

=head2 make_concatenation

    ->make_concatenation(ArrayRef[CodeRef] :$elements!)

=over

=item * Named Parameters:

=over

=item * ArrayRef[CodeRef] C<:$elements>

Callbacks returning values to concatenate.

=back

=back

Builds a callback returning a string of the values joined together without a separator.

=head2 make_constant

    ->make_constant(Any :$value!)

=over

=item * Named Parameters:

=over

=item * Any C<:$value>

=back

=back

Universal constant callback builder.

=head2 make_escape_scope

    ->make_escape_scope(CodeRef :$scope!)

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$scope>

=back

=back

Internal method.

=head2 make_escape_scope_exit

    ->make_escape_scope_exit(
        Str :$type!,
        ArrayRef[
            CodeRef
        ] :$values!
    )

=over

=item * Named Parameters:

=over

=item * Str C<:$type>

=item * ArrayRef[CodeRef] C<:$values>

Callbacks returning the values to put in the structural template.

=back

=back

Internal method.

=head2 make_getter

    ->make_getter(Str :$name!, Location :$location!)

=over

=item * Named Parameters:

=over

=item * L<Location|Language::SX::Types/Location> C<:$location>

The location of the variable access.

=item * Str C<:$name>

The name of the variable to get.

=back

=back

Builds a callback to fetch a value from the environment.

=head2 make_hash_builder

    ->make_hash_builder(ArrayRef[CodeRef] :$items!)

=over

=item * Named Parameters:

=over

=item * ArrayRef[CodeRef] C<:$items>

Even list of callbacks returning keys and values.

=back

=back

Builds a hash reference builder callback.

=head2 make_keyword_constant

    ->make_keyword_constant(Any :$value!)

=over

=item * Named Parameters:

=over

=item * Any C<:$value>

=back

=back

Builds a callback for constant keywords.

=head2 make_list_builder

    ->make_list_builder(ArrayRef[CodeRef] :$items!)

=over

=item * Named Parameters:

=over

=item * ArrayRef[CodeRef] C<:$items>

=back

=back

=head2 make_object_builder

    ->make_object_builder(
        Str :$class!,
        HashRef :$arguments!,
        Str :$cached_by
    )

=over

=item * Named Parameters:

=over

=item * HashRef C<:$arguments>

The constructor arguments.

=item * Str C<:$cached_by> (optional)

Name of the field in C<$arguments> that holds the cache key.

=item * Str C<:$class>

The class to instantiate.

=back

=back

Creates an (optionally cached) object creation callback.

=head2 make_regex_constant

    ->make_regex_constant(RegexpRef :$value!)

=over

=item * Named Parameters:

=over

=item * RegexpRef C<:$value>

=back

=back

Builds a callback for regular expression constants.

=head2 make_root

    ->make_root(CodeRef :$sequence!)

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$sequence>

=back

=back

Builds a callback to wrap the root sequence with the necessary input logic.

=head2 make_sequence

    ->make_sequence(ArrayRef[CodeRef] :$elements!)

=over

=item * Named Parameters:

=over

=item * ArrayRef[CodeRef] C<:$elements>

Callbacks returning values to concatenate.

=back

=back

Builds a callback that will evaluate all C<$elements> callbacks in turn and return
the value of the last element.

=head2 make_structure_builder

    ->make_structure_builder(
        ArrayRef[
            CodeRef
        ] :$values!,
        CodeRef :$template!
    )

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$template>

A code reference called with the values that go into the structure.

=item * ArrayRef[CodeRef] C<:$values>

Callbacks returning the values to put in the structural template.

=back

=back

Builds a data structure by weaving the C<$values> into the C<$template>.

=head2 map_libraries

Delegation to a generated L<map|Moose::Meta::Attribute::Native::MethodProvider::Array/map> method for the L<libraries|/libraries (required)> attribute.

C<map> for the libraries.

=head2 new_with_resolved_traits

    ->new_with_resolved_traits(ClassName $class: @args)

=over

=item * Positional Parameters:

=over

=item * C<@args>

Arguments for the L<Language::SX::Inflator::ValueScope> object.

=back

=back

Internal method for runtime inflation.

=head2 render_call

    ->render_call(
        Str :$method!,
        HashRef[
            Str
        ]|ArrayRef[
            Str
        ] :$args!,
        Str :$library
    )

=over

=item * Named Parameters:

=over

=item * ArrayRef[Str]|HashRef[Str] C<:$args>

Arguments for the method call. Either positional or named.

=item * Str C<:$library> (optional)

Library name if C<$method> is a library method.

=item * Str C<:$method>

Method name to call.

=back

=back

Render a call to an inflator or library method.

=head2 render_escape_wrap

    ->render_escape_wrap(Str $body)

=over

=item * Positional Parameters:

=over

=item * Str C<$body>

=back

=back

Internal method.

=head2 render_sequence

    ->render_sequence(ArrayRef[Object] $sequence)

=over

=item * Positional Parameters:

=over

=item * ArrayRef[Object] C<$sequence>

=back

=back

Renders code for a sequence iterator out of document items.

=head2 resolve_module_meta

    ->resolve_module_meta(ArrayRef[Object] $nodes)

=over

=item * Positional Parameters:

=over

=item * ArrayRef[Object] C<$nodes>

Root nodes.

=back

=back

Takes a list of nodes and returns an array reference of rest nodes plus an optional
L<Language::SX::Inflator::ModuleMeta> object if a C<module> directive was encountered
as first element.

=head2 serialize

    ->serialize()

=over

=back

=head2 with_lexicals

    ->with_lexicals(Str @lexicals)

=over

=item * Positional Parameters:

=over

=item * Str C<@lexicals>

=back

=back

Create a new inflator with additional known lexicals.

=head2 with_new_escape_scope

    ->with_new_escape_scope()

=over

=back

Internal method.

=head2 with_new_lexical_collector

    ->with_new_lexical_collector()

=over

=back

=head2 meta

Returns the meta object for C<Language::SX::Inflator> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 document_loader (required)

=over

=item * Type Constraint

CodeRef

=item * Constructor Argument

C<document_loader>

=item * Associated Methods

L<document_loader|/document_loader>

=back

Callback to load a new document.

=head2 libraries (required)

=over

=item * Type Constraint

L<LibraryList|Language::SX::Types/LibraryList>

=item * Default

Built during runtime.

=item * Constructor Argument

C<libraries>

=item * Associated Methods

L<map_libraries|/map_libraries>, L<all_libraries|/all_libraries>, L<find_library|/find_library>, L<add_library|/add_library>

=back

List of loaded library objects.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Document>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut
