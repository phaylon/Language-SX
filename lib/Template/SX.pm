use MooseX::Declare;

class Template::SX {

    with 'MooseX::Traits';

    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( CodeRef Str ArrayRef );
    use MooseX::MultiMethods;

    has reader => (
        is          => 'ro', 
        isa         => 'Template::SX::Reader', 
        required    => 1, 
        lazy_build  => 1,
        handles     => {
            read_string => 'read',
        },
    );

    has default_libraries => (
        is          => 'ro',
        isa         => LibraryList,
        required    => 1,
        coerce      => 1,
        default     => sub { to_LibraryList [qw( Core )] },
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

    multi method read (Str :$string) {
        return $self->read_string($string);
    }

    multi method load (Str :$string) {
        return $self->read_string($string)->load;
    }

    multi method run (Str :$string, HashRef :$vars = {}) {
        
        my $code = $self->load(string => $string);
        return scalar $code->(%$vars);
    }
}
