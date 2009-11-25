use MooseX::Declare;

class Template::SX::Exception::Insert extends Template::SX::Exception::File { }

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Exception::Insert
Error while inserting a document

@description
This exception will be thrown when an error occurred while inserting a document.

=end fusion






=head1 NAME

Template::SX::Exception::Insert - Error while inserting a document

=head1 INHERITANCE

=over 2

=item *

Template::SX::Exception::Insert

=over 2

=item *

L<Template::SX::Exception::File>

=over 2

=item *

L<Template::SX::Exception>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=back

=head1 DESCRIPTION

This exception will be thrown when an error occurred while inserting a document.

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

Initial value for the L<path|Template::SX::Exception::File/"path (required)"> attribute
inherited from L<Template::SX::Exception::File>.

=back

=head2 meta

Returns the meta object for C<Template::SX::Exception::Insert> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut