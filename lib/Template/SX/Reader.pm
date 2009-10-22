use MooseX::Declare;

class Template::SX::Reader {

    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( CodeRef Str ArrayRef );

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

    method read (Str $string) {

        require Template::SX::Reader::Stream;
        my $stream = Template::SX::Reader::Stream->new(content => $string);

        require Template::SX::Document;
        my $doc = Template::SX::Document->new_from_stream(
            $stream, 
            libraries   => [@{ $self->document_libraries }],
            traits      => [@{ $self->document_traits }],
        );

        return $doc;
    }
}
