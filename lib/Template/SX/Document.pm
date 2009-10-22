use MooseX::Declare;

class Template::SX::Document
    extends Template::SX::Document::Container {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( ArrayRef Object Bool Str );

    Class::MOP::load_class(E_INTERNAL);

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

    method compile () {
        require Template::SX::Inflator;

        my $inflator = Template::SX::Inflator->new_with_resolved_traits(
            libraries => [$self->all_libraries],
        );

        my $compiled = $inflator->compile_base([$self->all_nodes], $self->start_scope);
    }

    method new_from_stream (ClassName $class: Template::SX::Reader::Stream $stream, @for_new) {

        my $self = $class->new;
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
}
