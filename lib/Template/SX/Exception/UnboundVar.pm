use MooseX::Declare;

class Template::SX::Exception::UnboundVar
    extends Template::SX::Exception {

    use MooseX::Types::Moose qw( Str );

    has variable_name => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Exception::UnboundVar
Unbound variable exception

@attr variable_name
Name of the variable that could not be found.

@description
This exception will be thrown when you try to access a variable that does not
exist in the current environment.

=end fusion






=head1 NAME

Template::SX::Exception::UnboundVar - Unbound variable exception

=head1 INHERITANCE

=over 2

=item *

Template::SX::Exception::UnboundVar

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

This exception will be thrown when you try to access a variable that does not
exist in the current environment.

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

=item * variable_name (B<required>)

Initial value for the L<variable_name|/"variable_name (required)"> attribute.

=back

=head2 variable_name

Reader for the L<variable_name|/"variable_name (required)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Exception::UnboundVar> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 variable_name (required)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<variable_name>

=item * Associated Methods

L<variable_name|/variable_name>

=back

Name of the variable that could not be found.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut