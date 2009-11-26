use MooseX::Declare;

class Language::SX::Exception::Apply extends Language::SX::Exception {

}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Exception::Apply
Error during runtime application

@description
This exception will be raised when there was a general error during an application.

=end fusion






=head1 NAME

Language::SX::Exception::Apply - Error during runtime application

=head1 INHERITANCE

=over 2

=item *

Language::SX::Exception::Apply

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

This exception will be raised when there was a general error during an application.

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

=back

=head2 meta

Returns the meta object for C<Language::SX::Exception::Apply> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut