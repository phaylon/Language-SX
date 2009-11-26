use MooseX::Declare;

class Language::SX::Document::Number
    extends Language::SX::Document::Value {

    use Language::SX::Types  qw( Scope );
    use MooseX::Types::Moose qw( Num );

    has '+value' => (isa => Num);

    method compile (Language::SX::Inflator $inf, Scope $scope) {

        return $inf->render_call(
            method  => 'make_constant',
            args    => {
                value   => $self->value,
            },
        );
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Document::Number
Number constant values

@method compile
Compiles the number constant into a call to L<Language::SX::Inflator/make_constant>.

@attr value
Same as L<Language::SX::Document::Value/"value (required)"> but with a C<Num> type constraint.

@description
This is the document item class for number constants.

=end fusion






=head1 NAME

Language::SX::Document::Number - Number constant values

=head1 INHERITANCE

=over 2

=item *

Language::SX::Document::Number

=over 2

=item *

L<Language::SX::Document::Value>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This is the document item class for number constants.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Language::SX::Document::Value/"location (required)"> attribute
inherited from L<Language::SX::Document::Value>.

=item * value (B<required>)

Initial value for the L<value|/"value (required)"> attribute.

=back

=head2 compile

    ->compile(Language::SX::Inflator $inf, Scope $scope)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=item * L<Scope|Language::SX::Types/Scope> C<$scope>

=back

=back

Compiles the number constant into a call to L<Language::SX::Inflator/make_constant>.

=head2 value

Accessor for the L<value|/"value (required)"> attribute.

=head2 meta

Returns the meta object for C<Language::SX::Document::Number> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 value (required)

=over

=item * Type Constraint

Num

=item * Constructor Argument

C<value>

=item * Associated Methods

L<value|/value>

=back

Same as L<Language::SX::Document::Value/"value (required)"> but with a C<Num> type constraint.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut