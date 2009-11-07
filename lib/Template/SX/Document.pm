use MooseX::Declare;

class Template::SX::Document
    extends Template::SX::Document::Container {

    with 'MooseX::Traits';

    use Carp                        qw( croak );
    use Template::SX::Constants     qw( :all );
    use Template::SX::Types         qw( :all );
    use MooseX::Types::Moose        qw( ArrayRef HashRef Object Bool Str CodeRef );
    use MooseX::Types::Path::Class  qw( Dir File );
    use Path::Class                 qw( dir file );

    BEGIN {
        if ($Template::SX::TRACK_INSTANCES) {
            require MooseX::InstanceTracking;
            MooseX::InstanceTracking->import;
        }
    }

    Class::MOP::load_class($_)
        for E_INTERNAL, E_PROTOTYPE;

    has '+_trait_namespace' => (
        default     => 'Template::SX::Document::Trait',
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

    my $CoreLib = 'Template::SX::Library::Core';

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
        require Template::SX::Inflator;

        my $inflator = Template::SX::Inflator->new_with_resolved_traits(
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

        local $Template::SX::MODULE_META = $self->_module_meta;
        my $DOC_LOADER = $self->document_loader;
        my $code = eval sprintf 'package Template::SX::VOID; %s', $self->compiled_body;

        if ($@) {

            # FIXME throw exception
            die "Unable to load compiled code: $@\n";
        }
        elsif (not is_CodeRef $code) {

            # FIXME throw exception
            die "Invalid compilation result, not a code reference\n";
        }

        return $code;
    }

    method run (HashRef :$vars = {}, Bool :$persist, Dir :$include_path) {

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

    method new_from_stream (ClassName $class: Template::SX::Reader::Stream $stream, @for_new) {

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

    method new_node_from_stream (Object $stream, Token $token) {

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
