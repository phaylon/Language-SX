use MooseX::Declare;

class Template::SX::Document::Value 
    with Template::SX::Document::Locatable {

    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( Value );

    has value => (
        is          => 'rw',
        isa         => Value,
        required    => 1,
    );

    method compile (Template::SX::Inflator $inf, Scope $scope) {

        my $method = "compile_$scope";
        return $self->$method($inf);
    }

    method new_from_stream (ClassName $class: Template::SX::Document $doc, Template::SX::Reader::Stream $stream, Str $value, Location $loc) {

        return $class->new(value => $value, location => $loc);
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Document::Value
Value document item base class

@method compile
Will dispatch to C<compile_functional> or C<compile_structural> depending on
the C<$scope>.

@method new_from_stream
Default item from stream constructor that will take the value as it is.

@description
This is the base class for all value type document items.

=end fusion






=head1 NAME

Template::SX::Document::Value - Value document item base class

=head1 INHERITANCE

=over 2

=item *

Template::SX::Document::Value

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

This is the base class for all value type document items.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Template::SX::Document::Locatable/"location (required)"> attribute
composed in by L<Template::SX::Document::Locatable>.

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

Will dispatch to C<compile_functional> or C<compile_structural> depending on
the C<$scope>.

=head2 new_from_stream

    ->new_from_stream(
        ClassName $class:
        Template::SX::Document $doc,
        Template::SX::Reader::Stream $stream,
        Str $value,
        Location $loc
    )

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Document> C<$doc>

=item * L<Template::SX::Reader::Stream> C<$stream>

=item * Str C<$value>

=item * L<Location|Template::SX::Types/Location> C<$loc>

=back

=back

Default item from stream constructor that will take the value as it is.

=head2 value

Accessor for the L<value|/"value (required)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Document::Value> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 value (required)

=over

=item * Type Constraint

Value

=item * Constructor Argument

C<value>

=item * Associated Methods

L<value|/value>

=back

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut