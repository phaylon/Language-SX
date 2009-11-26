use MooseX::Declare;

class Language::SX::Document
    extends Language::SX::Document::Container {

    with 'MooseX::Traits';

    use TryCatch;
    use Carp                        qw( croak );
    use Language::SX::Constants     qw( :all );
    use Language::SX::Types         qw( :all );
    use MooseX::Types::Moose        qw( ArrayRef HashRef Object Bool Str CodeRef );
    use MooseX::Types::Path::Class  qw( Dir File );
    use Path::Class                 qw( dir file );
    use Data::Dump                  qw( pp );

    BEGIN {
        if ($Language::SX::TRACK_INSTANCES) {
            require MooseX::InstanceTracking;
            MooseX::InstanceTracking->import;
        }
    }

    Class::MOP::load_class($_)
        for E_INTERNAL, E_PROTOTYPE;

    has '+_trait_namespace' => (
        default     => 'Language::SX::Document::Trait',
    );

    has start_scope => (
        is          => 'ro',
        isa         => Scope,
        required    => 1,
        default     => SCOPE_FUNCTIONAL,
    );

    has source_name => (
        is          => 'ro',
        isa         => Str,
    );

    my $CoreLib = 'Language::SX::Library::Core';

    has libraries => (
        traits      => [qw( Array )],
        isa         => LibraryList,
        required    => 1,
        coerce      => 1,
        default     => sub { Class::MOP::load_class($CoreLib); [$CoreLib->new] },
        handles     => {
            add_library     => 'push',
            all_libraries   => 'elements',
        },
    );

    has compiled_body => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
        lazy_build  => 1,
    );

    has loaded_callback => (
        is          => 'ro',
        isa         => CodeRef,
        required    => 1,
        lazy_build  => 1,
    );

    has _object_cache => (
        is          => 'ro',
        isa         => HashRef,
        required    => 1,
        default     => sub { {} },
    );

    has _module_meta => (
        is          => 'ro',
        isa         => HashRef,
        required    => 1,
        default     => sub { {} },
    );

    has last_calculated_exports => (
#        isa         => HashRef,
        reader      => 'last_calculated_exports',
        writer      => '_set_last_calculated_exports',
        default     => sub { {} },
    );

    has document_loader => (
        is          => 'ro',
        isa         => CodeRef,
        required    => 1,
        default     => sub { {} },
    );

    has default_include_path => (
        is          => 'ro',
        isa         => Dir,
        required    => 1,
        default     => sub { dir '.' },
        writer      => '_set_default_include_path',
    );

    method compile () {
        require Language::SX::Inflator;

        my $inflator = Language::SX::Inflator->new_with_resolved_traits(
            libraries       => [$self->all_libraries],
            _object_cache   => $self->_object_cache,
            document_loader => $self->document_loader,
        );

        my $compiled = $inflator->compile_base([$self->all_nodes], $self->start_scope);

        return $compiled;
    }

    method _build_compiled_body () {
        my $compiled = $self->compile;
        print "COMPILED\n$compiled\n" if $ENV{DEV_SX_COMPILED};
        return $compiled;
    }

    method _build_loaded_callback () {
        return $self->load;
    }

    method load () {
        my $code;

        local $Language::SX::MODULE_META = $self->_module_meta;
        my $DOC_LOADER = $self->document_loader;

        $code = eval sprintf 'package Language::SX::VOID; %s', $self->compiled_body;

        if (my $e = $@) {
            die $e;
        }

        if (not is_CodeRef $code) {

            # FIXME throw exception
            die "Invalid compilation result, not a code reference\n";
        }

        return $code;
    }

#    method run (HashRef :$vars = {}, Bool :$persist, Dir :$include_path) {
    sub run {
        my ($self, %args) = @_;
        my $vars         = $args{vars} || {};
        my $persist      = $args{persist};
        my $include_path = $args{include_path};

        my $inner_vars  = $persist ? $vars : { %$vars };
        $include_path ||= $self->default_include_path;

        my $res = $self->loaded_callback->(
            vars => $inner_vars,
            path => $include_path,
        );

        if (my $exports = $self->_module_meta->{exports}) {

            $self->_set_last_calculated_exports({
                map { ($_ => $inner_vars->{ $_ }) } @{ $exports->{all} }
            });
        }

        return $res;

#        return $self->loaded_callback->($persist ? $vars : (%$vars));
    }

    method _export_info {

        $self->loaded_callback;
        return $self->_module_meta->{exports} || {};
    }

    method exported_groups () {

        return keys %{ $self->_export_info };
    }

    method exports_in_group (Str $group) {

        my $exports = $self->_export_info->{ $group }
            or E_PROTOTYPE->throw(
                class       => E_SYNTAX,
                attributes  => { message => "unknown export group '$group'" },
            );

        return @$exports;
    }

    method last_exported (Str $name) {

        my $export = $self->last_calculated_exports->{ $name }
            or E_PROTOTYPE->throw(
                class       => E_SYNTAX,
                attributes  => { message => "no value for '$name' was exported" },
            );

        return $export;
    }

    method new_from_stream (ClassName $class: Language::SX::Reader::Stream $stream, @for_new) {

        my $self = $class->new_with_traits(@for_new);
        $self->_populate_from_stream($stream);
        return $self;
    }

    method _populate_from_stream (Object $stream) {

        while (my $token = $stream->next_token) {

            my $node = $self->new_node_from_stream($stream, $token);

            $self->add_node($node)
                if defined $node;
        }
    }

    method new_node_from_stream (Language::SX::Reader::Stream $stream, Token $token) {

        my ($type, $value, $location) = @$token;

        my $method = $self->can($type . '_handler_class')
            or E_INTERNAL->throw(
                message     => "cannot handle $type token in stream",
                location    => $location,
            );

        my $handler = $self->$method;

        Class::MOP::load_class($handler);

        return $handler->new_from_stream($self, $stream, $value, $location);
    }

    method cell_open_handler_class  () { join '::', __PACKAGE__, 'Cell' }
    method bareword_handler_class   () { join '::', __PACKAGE__, 'Bareword' }
    method number_handler_class     () { join '::', __PACKAGE__, 'Number' }
    method string_handler_class     () { join '::', __PACKAGE__, 'String' }
    method quote_handler_class      () { join '::', __PACKAGE__, 'Quote' }
    method unquote_handler_class    () { join '::', __PACKAGE__, 'Quote' }
    method boolean_handler_class    () { join '::', __PACKAGE__, 'Boolean' }
    method keyword_handler_class    () { join '::', __PACKAGE__, 'Keyword' }
    method regex_handler_class      () { join '::', __PACKAGE__, 'Regex' }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Document
A L<Temülate::SX> document object.

@method compile
Compiles the stored document tree.

@method exported_groups
List of groups that can be exported by the document.

@method exports_in_group
%param $group Name of the group.
List of export names for a given group.

@method last_export
%param $name Name of the exported value.
Returns the last calculated value for a given exported variable.

@method load
Loads the L</compiled_body>.

@method new_from_stream
%param $stream  The stream to read from.
%param @for_new Arguments for the new document.
Create a new document out of a stream.

@method new_node_from_stream
%param $stream The stream to read for the next node.
%param $token  The initial token that determines the type of the node.
Create a new document node out of a stream.

@method run
%param :$include_path Where to look for files.
%param :$persist      If true, the C<$vars> won't be copied but used in-place.
%param :$vars         Initial variable values for the run.
Runs the L</loaded_callback> in a suitable document environment.

@attr compiled_body
The compiled body of the document inflation code.

@attr default_include_path
The include path to use by default.

@attr document_loader
Used to load new documents that have to be included.

@attr last_calculated_exports
Storage for the exported values that were calculated in the last run.

@attr source_name
Descriptive name of the source of the document, e.g. a filename.

@attr start_scope
Document root scope.

=end fusion






=head1 NAME

Language::SX::Document - A L<Temülate::SX> document object.

=head1 INHERITANCE

=over 2

=item *

Language::SX::Document

=over 2

=item *

L<Language::SX::Document::Container>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 APPLIED ROLES

=over

=item * L<MooseX::Traits>

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * compiled_body (optional)

Initial value for the L<compiled_body|/"compiled_body (required)"> attribute.

=item * default_include_path (optional)

Initial value for the L<default_include_path|/"default_include_path (required)"> attribute.

=item * document_loader (optional)

Initial value for the L<document_loader|/"document_loader (required)"> attribute.

=item * last_calculated_exports (optional)

Initial value for the L<last_calculated_exports|/"last_calculated_exports (optional)"> attribute.

=item * libraries (optional)

Initial value for the L<libraries|/"libraries (required)"> attribute.

=item * loaded_callback (optional)

Initial value for the L<loaded_callback|/"loaded_callback (required)"> attribute.

=item * nodes (optional)

Initial value for the L<nodes|Language::SX::Document::Container/"nodes (required)"> attribute
inherited from L<Language::SX::Document::Container>.

=item * source_name (optional)

Initial value for the L<source_name|/"source_name (optional)"> attribute.

=item * start_scope (optional)

Initial value for the L<start_scope|/"start_scope (required)"> attribute.

=back

=head2 add_library

Delegation to a generated L<push|Moose::Meta::Attribute::Native::MethodProvider::Array/push> method for the L<libraries|/libraries (required)> attribute.

=head2 all_libraries

Delegation to a generated L<elements|Moose::Meta::Attribute::Native::MethodProvider::Array/elements> method for the L<libraries|/libraries (required)> attribute.

=head2 bareword_handler_class

    ->bareword_handler_class()

=over

=back

=head2 boolean_handler_class

    ->boolean_handler_class()

=over

=back

=head2 cell_open_handler_class

    ->cell_open_handler_class()

=over

=back

=head2 clear_compiled_body

Clearer for the L<compiled_body|/"compiled_body (required)"> attribute.

=head2 clear_loaded_callback

Clearer for the L<loaded_callback|/"loaded_callback (required)"> attribute.

=head2 compile

    ->compile()

=over

=back

Compiles the stored document tree.

=head2 compiled_body

Reader for the L<compiled_body|/"compiled_body (required)"> attribute.

=head2 default_include_path

Reader for the L<default_include_path|/"default_include_path (required)"> attribute.

=head2 document_loader

Reader for the L<document_loader|/"document_loader (required)"> attribute.

=head2 exported_groups

    ->exported_groups()

=over

=back

List of groups that can be exported by the document.

=head2 exports_in_group

    ->exports_in_group(Str $group)

=over

=item * Positional Parameters:

=over

=item * Str C<$group>

Name of the group.

=back

=back

List of export names for a given group.

=head2 has_compiled_body

Predicate for the L<compiled_body|/"compiled_body (required)"> attribute.

=head2 has_loaded_callback

Predicate for the L<loaded_callback|/"loaded_callback (required)"> attribute.

=head2 keyword_handler_class

    ->keyword_handler_class()

=over

=back

=head2 last_calculated_exports

Reader for the L<last_calculated_exports|/"last_calculated_exports (optional)"> attribute.

=head2 last_exported

    ->last_exported(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

=head2 load

    ->load()

=over

=back

Loads the L</compiled_body>.

=head2 loaded_callback

Reader for the L<loaded_callback|/"loaded_callback (required)"> attribute.

=head2 new_from_stream

    ->new_from_stream(
        ClassName $class:
        Language::SX::Reader::Stream $stream,
        @for_new
    )

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Reader::Stream> C<$stream>

The stream to read for the next node.

=item * C<@for_new>

Arguments for the new document.

=back

=back

Create a new document out of a stream.

=head2 new_node_from_stream

    ->new_node_from_stream(
        Language::SX::Reader::Stream $stream,
        Token $token
    )

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Reader::Stream> C<$stream>

The stream to read for the next node.

=item * L<Token|Language::SX::Types/Token> C<$token>

The initial token that determines the type of the node.

=back

=back

Create a new document node out of a stream.

=head2 number_handler_class

    ->number_handler_class()

=over

=back

=head2 quote_handler_class

    ->quote_handler_class()

=over

=back

=head2 regex_handler_class

    ->regex_handler_class()

=over

=back

=head2 run

    ->run(HashRef :$vars = {}, Bool :$persist, Dir :$include_path)

=over

=item * Named Parameters:

=over

=item * L<Dir|MooseX::Types::Path::Class/Dir> C<:$include_path> (optional)

Where to look for files.

=item * Bool C<:$persist> (optional)

If true, the C<$vars> won't be copied but used in-place.

=item * HashRef C<:$vars> (optional)

Initial variable values for the run.

=back

=back

Runs the L</loaded_callback> in a suitable document environment.

=head2 source_name

Reader for the L<source_name|/"source_name (optional)"> attribute.

=head2 start_scope

Reader for the L<start_scope|/"start_scope (required)"> attribute.

=head2 string_handler_class

    ->string_handler_class()

=over

=back

=head2 unquote_handler_class

    ->unquote_handler_class()

=over

=back

=head2 meta

Returns the meta object for C<Language::SX::Document> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 compiled_body (required)

=over

=item * Type Constraint

Str

=item * Default

Built lazily during runtime.

=item * Constructor Argument

C<compiled_body>

=item * Associated Methods

L<compiled_body|/compiled_body>, L<has_compiled_body|/has_compiled_body>, L<clear_compiled_body|/clear_compiled_body>

=back

The compiled body of the document inflation code.

=head2 default_include_path (required)

=over

=item * Type Constraint

L<Dir|MooseX::Types::Path::Class/Dir>

=item * Default

Built during runtime.

=item * Constructor Argument

C<default_include_path>

=item * Associated Methods

L<default_include_path|/default_include_path>

=back

The include path to use by default.

=head2 document_loader (required)

=over

=item * Type Constraint

CodeRef

=item * Default

Built during runtime.

=item * Constructor Argument

C<document_loader>

=item * Associated Methods

L<document_loader|/document_loader>

=back

Used to load new documents that have to be included.

=head2 last_calculated_exports (optional)

=over

=item * Default

Built during runtime.

=item * Constructor Argument

C<last_calculated_exports>

=item * Associated Methods

L<last_calculated_exports|/last_calculated_exports>

=back

Storage for the exported values that were calculated in the last run.

=head2 libraries (required)

=over

=item * Type Constraint

L<LibraryList|Language::SX::Types/LibraryList>

=item * Default

Built during runtime.

=item * Constructor Argument

C<libraries>

=item * Associated Methods

L<all_libraries|/all_libraries>, L<add_library|/add_library>

=back

=head2 loaded_callback (required)

=over

=item * Type Constraint

CodeRef

=item * Default

Built lazily during runtime.

=item * Constructor Argument

C<loaded_callback>

=item * Associated Methods

L<loaded_callback|/loaded_callback>, L<has_loaded_callback|/has_loaded_callback>, L<clear_loaded_callback|/clear_loaded_callback>

=back

=head2 source_name (optional)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<source_name>

=item * Associated Methods

L<source_name|/source_name>

=back

Descriptive name of the source of the document, e.g. a filename.

=head2 start_scope (required)

=over

=item * Type Constraint

L<Scope|Language::SX::Types/Scope>

=item * Default

C<functional>

=item * Constructor Argument

C<start_scope>

=item * Associated Methods

L<start_scope|/start_scope>

=back

Document root scope.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut
