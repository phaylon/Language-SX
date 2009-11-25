use MooseX::Declare;

class Template::SX::Exception::Prototype is dirty {

    use Template::SX::Types  qw( Location );
    use MooseX::Types::Moose qw( Str HashRef );

    clean;
    use overload '""' => 'as_string', fallback => 1;

    has class => (
        is          => 'ro',
        isa         =>  Str,
        required    => 1,
    );

    has attributes => (
        is          => 'ro',
        isa         => HashRef,
        required    => 1,
    );

    method throw (ClassName $class: @args) { die $class->new(@args) }

    method rethrow () { die $self }

    method throw_at (Location $loc) {

        Class::MOP::load_class($self->class);
        $self->class->throw(%{ $self->attributes }, location => $loc);
    }

    sub as_string { $_[0]->attributes->{message} }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Exception
@license  Template::SX

@class Template::SX::Exception::Prototype
Exception prototypes without locations

@method as_string
Returns the message and ignores all attributes so it can be a target for string
L<overloading|overload>.

@method rethrow
This will throw an already existing prototype exception.

@method throw
%param @args Everything that should be passed to L</new>.
Throws the exception.

@method throw_at
This will throw the real prototyped exception with the specified location.

@attr attributes
The constructor attributes for the real exception.

@attr class
The class of the real exception.

@description
This is not a usual L<Template::SX::Exception>. It is a location-less prototype
exception that can be thrown, but gives internal parts of L<Template::SX> the
possibility to interject it and attach a location to it.

=end fusion






=head1 NAME

Template::SX::Exception::Prototype - Exception prototypes without locations

=head1 INHERITANCE

=over 2

=item *

Template::SX::Exception::Prototype

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This is not a usual L<Template::SX::Exception>. It is a location-less prototype
exception that can be thrown, but gives internal parts of L<Template::SX> the
possibility to interject it and attach a location to it.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * attributes (B<required>)

Initial value for the L<attributes|/"attributes (required)"> attribute.

=item * class (B<required>)

Initial value for the L<class|/"class (required)"> attribute.

=back

=head2 as_string

Returns the message and ignores all attributes so it can be a target for string
L<overloading|overload>.

=head2 attributes

Reader for the L<attributes|/"attributes (required)"> attribute.

=head2 class

Reader for the L<class|/"class (required)"> attribute.

=head2 rethrow

    ->rethrow()

=over

=back

This will throw an already existing prototype exception.

=head2 throw

    ->throw(ClassName $class: @args)

=over

=item * Positional Parameters:

=over

=item * C<@args>

Everything that should be passed to L</new>.

=back

=back

Throws the exception.

=head2 throw_at

    ->throw_at(Location $loc)

=over

=item * Positional Parameters:

=over

=item * L<Location|Template::SX::Types/Location> C<$loc>

=back

=back

This will throw the real prototyped exception with the specified location.

=head2 meta

Returns the meta object for C<Template::SX::Exception::Prototype> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 attributes (required)

=over

=item * Type Constraint

HashRef

=item * Constructor Argument

C<attributes>

=item * Associated Methods

L<attributes|/attributes>

=back

The constructor attributes for the real exception.

=head2 class (required)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<class>

=item * Associated Methods

L<class|/class>

=back

The class of the real exception.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Exception>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut