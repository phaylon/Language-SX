use MooseX::Declare;

class Language::SX::Inflator::Precompiled with Language::SX::Document::Locatable {

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

@see_also Language::SX
@see_also Language::SX::Inflator
@see_also Language::SX::Document
@license  Language::SX

@class Language::SX::Inflator::Precompiled
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

Language::SX::Inflator::Precompiled - Precompiled document item

=head1 INHERITANCE

=over 2

=item *

Language::SX::Inflator::Precompiled

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<Language::SX::Document::Locatable>

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

Initial value for the L<location|Language::SX::Document::Locatable/"location (required)"> attribute
composed in by L<Language::SX::Document::Locatable>.

=back

=head2 compile

    ->compile(@)

=over

=back

Simply returns the precompiled content.

=head2 compiled

Reader for the L<compiled|/"compiled (required)"> attribute.

=head2 meta

Returns the meta object for C<Language::SX::Inflator::Precompiled> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

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

=item * L<Language::SX>

=item * L<Language::SX::Inflator>

=item * L<Language::SX::Document>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut