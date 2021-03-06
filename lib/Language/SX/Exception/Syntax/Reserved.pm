use MooseX::Declare;

class Language::SX::Exception::Syntax::Reserved 
    extends Language::SX::Exception::Syntax {

    use MooseX::Types::Moose qw( Str );

    has identifier => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );

    has library => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Exception::Syntax::Reserved
Tried to override a syntax identifier

@description
This exception will be raised when you try to declare a variable with the same name
as an existing syntax element.

@attr identifier
The identifier in question.

@attr library
The library in which it was found as syntax element.

=end fusion






=head1 NAME

Language::SX::Exception::Syntax::Reserved - Tried to override a syntax identifier

=head1 INHERITANCE

=over 2

=item *

Language::SX::Exception::Syntax::Reserved

=over 2

=item *

L<Language::SX::Exception::Syntax>

=over 2

=item *

L<Language::SX::Exception>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=back

=head1 DESCRIPTION

This exception will be raised when you try to declare a variable with the same name
as an existing syntax element.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * identifier (B<required>)

Initial value for the L<identifier|/"identifier (required)"> attribute.

=item * library (B<required>)

Initial value for the L<library|/"library (required)"> attribute.

=item * location (B<required>)

Initial value for the L<location|Language::SX::Exception/"location (required)"> attribute
inherited from L<Language::SX::Exception>.

=item * message (B<required>)

Initial value for the L<message|Language::SX::Exception/"message (required)"> attribute
inherited from L<Language::SX::Exception>.

=back

=head2 identifier

Reader for the L<identifier|/"identifier (required)"> attribute.

=head2 library

Reader for the L<library|/"library (required)"> attribute.

=head2 meta

Returns the meta object for C<Language::SX::Exception::Syntax::Reserved> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 identifier (required)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<identifier>

=item * Associated Methods

L<identifier|/identifier>

=back

The identifier in question.

=head2 library (required)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<library>

=item * Associated Methods

L<library|/library>

=back

The library in which it was found as syntax element.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut