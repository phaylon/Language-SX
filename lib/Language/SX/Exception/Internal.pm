use MooseX::Declare;

class Language::SX::Exception::Internal {
    extends 'Language::SX::Exception';

    1;
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Exception::Internal
Internal or general usage exception

@description
This exception will be raised whenever an internal error occurred or there was
a mistake in the general usage of one of the modules or features.

=end fusion






=head1 NAME

Language::SX::Exception::Internal - Internal or general usage exception

=head1 INHERITANCE

=over 2

=item *

Language::SX::Exception::Internal

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

This exception will be raised whenever an internal error occurred or there was
a mistake in the general usage of one of the modules or features.

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

Returns the meta object for C<Language::SX::Exception::Internal> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut