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

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Reader::Stream
@see_also Template::SX::Document
@license  Template::SX

@class Template::SX::Reader
Transform a source into a L<Template::SX::Document>.

@method create_stream
%param $string The string that should be turned into a L<stream|Template::SX::Reader::Stream>.
%param $source_name Name of the source, e.g. a filename.
Creates a new stream for the C<$string>.

@method read
%param $string The string to read.
%param $source_name Name of the source, e.g. a filename.
Turns a C<$string> into a L<stream|Template::SX::Reader::Stream>.

@attr document_libraries
List of libraries for new documents.

@attr document_loader
Callback to load new documents.

@attr document_traits
Traits to apply to new documents.

=end fusion






=head1 NAME

Template::SX::Reader - Transform a source into a L<Template::SX::Document>.

=head1 INHERITANCE

=over 2

=item *

Template::SX::Reader

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * document_libraries (optional)

Initial value for the L<document_libraries|/"document_libraries (required)"> attribute.

=item * document_loader (B<required>)

Initial value for the L<document_loader|/"document_loader (required)"> attribute.

=item * document_traits (optional)

Initial value for the L<document_traits|/"document_traits (required)"> attribute.

=back

=head2 create_stream

    ->create_stream(Str $string, Str $source_name?)

=over

=item * Positional Parameters:

=over

=item * Str C<$string>

The string to read.

=item * Str C<$source_name> (optional)

Name of the source, e.g. a filename.

=back

=back

Creates a new stream for the C<$string>.

=head2 document_libraries

Reader for the L<document_libraries|/"document_libraries (required)"> attribute.

=head2 document_loader

Reader for the L<document_loader|/"document_loader (required)"> attribute.

=head2 document_traits

Reader for the L<document_traits|/"document_traits (required)"> attribute.

=head2 read

    ->read(Str $string, Str $source_name?)

=over

=item * Positional Parameters:

=over

=item * Str C<$string>

The string to read.

=item * Str C<$source_name> (optional)

Name of the source, e.g. a filename.

=back

=back

Turns a C<$string> into a L<stream|Template::SX::Reader::Stream>.

=head2 meta

Returns the meta object for C<Template::SX::Reader> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 document_libraries (required)

=over

=item * Type Constraint

L<LibraryList|Template::SX::Types/LibraryList>

=item * Default

Built during runtime.

=item * Constructor Argument

C<document_libraries>

=item * Associated Methods

L<document_libraries|/document_libraries>

=back

List of libraries for new documents.

=head2 document_loader (required)

=over

=item * Type Constraint

CodeRef

=item * Constructor Argument

C<document_loader>

=item * Associated Methods

L<document_loader|/document_loader>

=back

Callback to load new documents.

=head2 document_traits (required)

=over

=item * Type Constraint

ArrayRef[Str]

=item * Default

Built during runtime.

=item * Constructor Argument

C<document_traits>

=item * Associated Methods

L<document_traits|/document_traits>

=back

Traits to apply to new documents.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Reader::Stream>

=item * L<Template::SX::Document>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut