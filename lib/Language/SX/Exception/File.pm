use MooseX::Declare;

class Language::SX::Exception::File extends Language::SX::Exception {

    use MooseX::Types::Path::Class qw( File );

    has path => (
        is          => 'ro',
        isa         => File,
        required    => 1,
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Exception::File
Exception during the handling of a file

@description
This exception will be raised whenver an error occured while handling a file.

@attr path
The path to the file that was handled.

=end fusion






=head1 NAME

Language::SX::Exception::File - Exception during the handling of a file

=head1 INHERITANCE

=over 2

=item *

Language::SX::Exception::File

=over 2

=item *

L<Language::SX::Exception>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This exception will be raised whenver an error occured while handling a file.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Language::SX::Exception/"location (required)"> attribute
inherited from L<Language::SX::Exception>.

=item * message (B<required>)

Initial value for the L<message|Language::SX::Exception/"message (required)"> attribute
inherited from L<Language::SX::Exception>.

=item * path (B<required>)

Initial value for the L<path|/"path (required)"> attribute.

=back

=head2 path

Reader for the L<path|/"path (required)"> attribute.

=head2 meta

Returns the meta object for C<Language::SX::Exception::File> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 path (required)

=over

=item * Type Constraint

L<File|MooseX::Types::Path::Class/File>

=item * Constructor Argument

C<path>

=item * Associated Methods

L<path|/path>

=back

The path to the file that was handled.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut