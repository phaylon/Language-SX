use MooseX::Declare;

class Template::SX::Exception::File extends Template::SX::Exception {

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

@see_also Template::SX
@license  Template::SX

@class Template::SX::Exception::File
Exception during the handling of a file

@description
This exception will be raised whenver an error occured while handling a file.

@attr path
The path to the file that was handled.

=end fusion






=head1 NAME

Template::SX::Exception::File - Exception during the handling of a file

=head1 INHERITANCE

=over 2

=item *

Template::SX::Exception::File

=over 2

=item *

L<Template::SX::Exception>

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

Initial value for the L<location|Template::SX::Exception/"location (required)"> attribute
inherited from L<Template::SX::Exception>.

=item * message (B<required>)

Initial value for the L<message|Template::SX::Exception/"message (required)"> attribute
inherited from L<Template::SX::Exception>.

=item * path (B<required>)

Initial value for the L<path|/"path (required)"> attribute.

=back

=head2 path

Reader for the L<path|/"path (required)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Exception::File> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

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

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut