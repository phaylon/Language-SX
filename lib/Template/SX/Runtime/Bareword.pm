use MooseX::Declare;

class Template::SX::Runtime::Bareword is dirty {

    use MooseX::Types::Moose qw( Str );

    clean;

    # inlined for speed optimisation
    use overload '""' => sub { $_[0]->value }, fallback => 1;

    has value => (
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

@class Template::SX::Runtime::Bareword
A quoted bareword during runtime

@description
This class will be used to pass quoted barewords around during runtime. The objects
will stringify to the bareword's value.

You can create these objects yourself. Note however that those created by L<Template::SX>
might be cached and not exclusively used by you.

!TAG<runtime value>
!TAG<barewords>

@attr value
The value, or name, of the bareword.

=end fusion






=head1 NAME

Template::SX::Runtime::Bareword - A quoted bareword during runtime

=head1 INHERITANCE

=over 2

=item *

Template::SX::Runtime::Bareword

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This class will be used to pass quoted barewords around during runtime. The objects
will stringify to the bareword's value.

You can create these objects yourself. Note however that those created by L<Template::SX>
might be cached and not exclusively used by you.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * value (B<required>)

Initial value for the L<value|/"value (required)"> attribute.

=back

=head2 value

Reader for the L<value|/"value (required)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Runtime::Bareword> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 value (required)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<value>

=item * Associated Methods

L<value|/value>

=back

The value, or name, of the bareword.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut