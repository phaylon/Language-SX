use MooseX::Declare;

class Template::SX::Reader {

    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( CodeRef Str ArrayRef HashRef );

    has document_libraries => (
        is          => 'ro',
        isa         => LibraryList,
        required    => 1,
        default     => sub { [] },
    );

    has document_traits => (
        is          => 'ro',
        isa         => ArrayRef[Str],
        required    => 1,
        default     => sub { [] },
    );

    has document_loader => (
        is          => 'ro',
        isa         => CodeRef,
        required    => 1,
    );

    method create_stream (Str $string, Str $source_name?) {

        require Template::SX::Reader::Stream;
        return Template::SX::Reader::Stream->new(
            content     => $string,
          ( $source_name ? (source_name => $source_name) : () ),
        );
    }

    method read (Str $string, Str $source_name?) {

        my $stream = $self->create_stream($string, $source_name || ());

        require Template::SX::Document;
        my $doc = Template::SX::Document->new_from_stream(
            $stream, 
            libraries       => [@{ $self->document_libraries }],
            traits          => [@{ $self->document_traits }],
          ( $source_name ? (source_name => $source_name) : () ),
            document_loader => $self->document_loader,
        );

        return $doc;
    }
}
