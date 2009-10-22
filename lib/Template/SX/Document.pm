use MooseX::Declare;

class Template::SX::Document
    extends Template::SX::Document::Container {

    with 'MooseX::Traits';

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( ArrayRef Object Bool Str CodeRef );

    Class::MOP::load_class(E_INTERNAL);

    has '+_trait_namespace' => (
        default     => 'Template::SX::Document::Trait',
    );

    has start_scope => (
        is          => 'ro',
        isa         => Scope,
        required    => 1,
        default     => SCOPE_FUNCTIONAL,
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

    method compile () {
        require Template::SX::Inflator;

        my $inflator = Template::SX::Inflator->new_with_resolved_traits(
            libraries => [$self->all_libraries],
        );

        my $compiled = $inflator->compile_base([$self->all_nodes], $self->start_scope);

        return $compiled;
    }

    method _build_compiled_body () {
        my $compiled = $self->compile;
        print "COMPILED\n$compiled\n";
        return $compiled;
    }

    method _build_loaded_callback () {
        return $self->load;
    }

    method load () {

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

    method run (HashRef :$vars = {}) {
        return $self->load->(%$vars);
    }

    method new_from_stream (ClassName $class: Template::SX::Reader::Stream $stream, @for_new) {

        my $self = $class->new_with_traits(@for_new);
        $self->_populate_from_stream($stream);
        return $self;
    }

    method _populate_from_stream (Object $stream) {

        while (my $token = $stream->next_token) {
            $self->add_node($self->new_node_from_stream($stream, $token));
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
}
