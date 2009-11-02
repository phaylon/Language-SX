use MooseX::Declare;

class Template::SX {

    with 'MooseX::Traits';

    use Template::SX::Types         qw( :all );
    use MooseX::Types::Moose        qw( CodeRef Str HashRef Bool ArrayRef );
    use MooseX::Types::Path::Class  qw( File Dir );
    use MooseX::MultiMethods;
    use MooseX::StrictConstructor;
    use Path::Class                 qw( file dir );

    BEGIN {
        if ($Template::SX::TRACK_INSTANCES) {
            require MooseX::InstanceTracking;
            MooseX::InstanceTracking->import;
        }
    }

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

    has include_path => (
        is          => 'ro',
        isa         => Dir,
        default     => sub { dir '.' },
        required    => 1,
        coerce      => 1,
    );

    has use_global_cache => (
        is          => 'ro',
        isa         => Bool,
    );

    my %GlobalCache;

    has _document_cache => (
        is          => 'ro',
        isa         => HashRef,
        required    => 1,
        lazy        => 1,
        default     => sub { $_[0]->use_global_cache ? \%GlobalCache : {} },
    );

    has '+_trait_namespace' => (
        default     => 'Template::SX::Trait',
    );

    method _build_reader {

        require Template::SX::Reader;
        return Template::SX::Reader->new(
            document_libraries  => [@{ $self->default_libraries }],
            document_traits     => [@{ $self->document_traits }],
            document_cache      => $self->_document_cache,
        );
    }

    method all_function_names { map { ($_->function_names) } @{ $self->default_libraries } }
    method all_syntax_names   { map { ($_->syntax_names) }   @{ $self->default_libraries } }


    method read (SourceType $type, Any $source, Str :$source_name?) {
        my $doc = $self->can("_read_${type}")->($self, $source, $source_name || ());
        $doc->_set_default_include_path($self->include_path);
        return $doc;
    }

    method _read_string (Str $source, Str $source_name?) {
        return $self->_document_from_string($source, $source_name || ());
    }

    method _read_file (File $source does coerce) {
        my $content = $source->slurp;
        return $self->_document_from_string($content, $source->absolute->stringify);
    }


    method run (SourceType $type, Any $source, HashRef :$vars = {}, Bool :$persist, Str :$source_name?) {

        my $doc = $self->read($type, $source, $source_name ? (source_name => $source_name) : ());

        return $doc->run(
            vars            => $vars, 
            persist         => $persist, 
            include_path    => $self->include_path,
        );
    }
}
