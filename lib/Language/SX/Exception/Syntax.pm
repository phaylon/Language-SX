use MooseX::Declare;

class Language::SX::Exception::Syntax 
    extends Language::SX::Exception {

}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Exception::Syntax
Syntax error

@description
This kind of exception will be raised whenever there was an error in the syntax
of the code.

=end fusion






=head1 NAME

Language::SX::Exception::Syntax - Syntax error

=head1 INHERITANCE

=over 2

=item *

Language::SX::Exception::Syntax

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

This kind of exception will be raised whenever there was an error in the syntax
of the code.

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

Returns the meta object for C<Language::SX::Exception::Syntax> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut