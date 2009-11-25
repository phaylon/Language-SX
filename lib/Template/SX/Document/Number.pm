use MooseX::Declare;

class Template::SX::Document::Number
    extends Template::SX::Document::Value {

    use Template::SX::Types  qw( Scope );
    use MooseX::Types::Moose qw( Num );

    has '+value' => (isa => Num);

    method compile (Template::SX::Inflator $inf, Scope $scope) {

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

@see_also Template::SX
@license  Template::SX

@class Template::SX::Document::Number
Number constant values

@method compile
Compiles the number constant into a call to L<Template::SX::Inflator/make_constant>.

@attr value
Same as L<Template::SX::Document::Value/"value (required)"> but with a C<Num> type constraint.

@description
This is the document item class for number constants.

=end fusion






=head1 NAME

Template::SX::Document::Number - Number constant values

=head1 INHERITANCE

=over 2

=item *

Template::SX::Document::Number

=over 2

=item *

L<Template::SX::Document::Value>

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

Initial value for the L<location|Template::SX::Document::Value/"location (required)"> attribute
inherited from L<Template::SX::Document::Value>.

=item * value (B<required>)

Initial value for the L<value|/"value (required)"> attribute.

=back

=head2 compile

    ->compile(Template::SX::Inflator $inf, Scope $scope)

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=item * L<Scope|Template::SX::Types/Scope> C<$scope>

=back

=back

Compiles the number constant into a call to L<Template::SX::Inflator/make_constant>.

=head2 value

Accessor for the L<value|/"value (required)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Document::Number> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

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

Same as L<Template::SX::Document::Value/"value (required)"> but with a C<Num> type constraint.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut