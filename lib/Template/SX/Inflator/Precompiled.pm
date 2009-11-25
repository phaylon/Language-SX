use MooseX::Declare;

class Template::SX::Inflator::Precompiled with Template::SX::Document::Locatable {

    use MooseX::Types::Moose qw( Str );

    has compiled => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );

    method compile { $self->compiled }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Inflator
@see_also Template::SX::Document
@license  Template::SX

@class Template::SX::Inflator::Precompiled
Precompiled document item

@method compile
Simply returns the precompiled content.

@attr compiled
The precompiled code.

@description
This class is used internally to pass around precompiled pieces of code that can
be compiled like any other document item.

=end fusion






=head1 NAME

Template::SX::Inflator::Precompiled - Precompiled document item

=head1 INHERITANCE

=over 2

=item *

Template::SX::Inflator::Precompiled

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<Template::SX::Document::Locatable>

=back

=head1 DESCRIPTION

This class is used internally to pass around precompiled pieces of code that can
be compiled like any other document item.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * compiled (B<required>)

Initial value for the L<compiled|/"compiled (required)"> attribute.

=item * location (B<required>)

Initial value for the L<location|Template::SX::Document::Locatable/"location (required)"> attribute
composed in by L<Template::SX::Document::Locatable>.

=back

=head2 compile

    ->compile(@)

=over

=back

Simply returns the precompiled content.

=head2 compiled

Reader for the L<compiled|/"compiled (required)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Inflator::Precompiled> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 compiled (required)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<compiled>

=item * Associated Methods

L<compiled|/compiled>

=back

The precompiled code.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Inflator>

=item * L<Template::SX::Document>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut