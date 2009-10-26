use MooseX::Declare;

class Template::SX {

    with 'MooseX::Traits';

    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( CodeRef Str ArrayRef );
    use MooseX::MultiMethods;

    our $VERSION = '0.001';

    has reader => (
        is          => 'ro', 
        isa         => 'Template::SX::Reader', 
        required    => 1, 
        lazy_build  => 1,
        handles     => {
            _document_from_string   => 'read',
            _stream_from_string     => 'create_stream',
        },
    );

    has default_libraries => (
        is          => 'ro',
        isa         => LibraryList,
        required    => 1,
        coerce      => 1,
        default     => sub { require Template::SX::Library::Core; [Template::SX::Library::Core->new] },
    );

    has document_traits => (
        is          => 'ro',
        isa         => ArrayRef[Str],
        required    => 1,
        default     => sub { [] },
    );

    has '+_trait_namespace' => (
        default     => 'Template::SX::Trait',
    );

    method _build_reader {

        require Template::SX::Reader;
        return Template::SX::Reader->new(
            document_libraries  => [@{ $self->default_libraries }],
            document_traits     => [@{ $self->document_traits }],
        );
    }

    method all_function_names { map { ($_->function_names) } @{ $self->default_libraries } }
    method all_syntax_names   { map { ($_->syntax_names) }   @{ $self->default_libraries } }


    method read (SourceType $type, Any $source, Str :$source_name?) {
        return $self->can("_read_${type}")->($self, $source, $source_name || ());
    }

    method _read_string (Str $source, Str $source_name?) {
        return $self->_document_from_string($source, $source_name || ());
    }


    method run (SourceType $type, Any $source, HashRef :$vars = {}, Bool :$persist, Str :$source_name?) {

        my $doc = $self->read($type, $source, $source_name ? (source_name => $source_name) : ());
        return $doc->run(vars => $vars, persist => $persist);
    }
}
