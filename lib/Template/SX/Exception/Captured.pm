use MooseX::Declare;

class Template::SX::Exception::Captured extends Template::SX::Exception {

    has captured => (
        is          => 'ro',
        required    => 1,
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Exception::Captured
External captured exception

@attr captured
The captured exception.

@description
Whenever an exception is encountered that does not come from L<Template::SX> it will
be wrapped in this class so that it can be pinned to a location.

=end fusion






=head1 NAME

Template::SX::Exception::Captured - External captured exception

=head1 INHERITANCE

=over 2

=item *

Template::SX::Exception::Captured

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

Whenever an exception is encountered that does not come from L<Template::SX> it will
be wrapped in this class so that it can be pinned to a location.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * captured (B<required>)

Initial value for the L<captured|/"captured (required)"> attribute.

=item * location (B<required>)

Initial value for the L<location|Template::SX::Exception/"location (required)"> attribute
inherited from L<Template::SX::Exception>.

=item * message (B<required>)

Initial value for the L<message|Template::SX::Exception/"message (required)"> attribute
inherited from L<Template::SX::Exception>.

=back

=head2 captured

Reader for the L<captured|/"captured (required)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Exception::Captured> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 captured (required)

=over

=item * Constructor Argument

C<captured>

=item * Associated Methods

L<captured|/captured>

=back

The captured exception.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut