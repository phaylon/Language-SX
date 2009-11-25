use MooseX::Declare;

class Template::SX::Library::Data::Objects extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Call::Tail;
    use Scalar::Util            qw( blessed );
    use Sub::Name               qw( subname );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';

    CLASS->add_functions(
        'object?' => CLASS->wrap_function('object', { min => 1 }, sub {
            return scalar( grep { not(blessed($_)) or $_->isa('Moose::Meta::TypeConstraint') } @_ ) ? undef : 1;
        }),
        'class-of' => CLASS->wrap_function('class-of', { min => 1, max => 1, types => [qw( object )] }, sub {
            return blessed shift;
        }),
        'is-a?' => CLASS->wrap_function('is-a?', { min => 2, max => 2 }, sub {
            my ($item, $class) = @_;

            return undef 
                unless ( blessed($item) and not $item->isa('Moose::Meta::TypeConstraint') )
                    or ( defined($item) and not ref($item) );

            return $item->isa($class) ? 1 : undef;
        }),
        'does?' => CLASS->wrap_function('does?', { min => 2, max => 2 }, sub {
            my ($item, $role) = @_;

            return undef 
                unless ( blessed($item) and not $item->isa('Moose::Meta::TypeConstraint') )
                    or ( defined($item) and not ref($item) );

            return $item->DOES($role) ? 1 : undef;
        }),
    );

    CLASS->add_functions(
        'object-invocant' => CLASS->wrap_function('object-invocant', { min => 1, max => 1 }, sub {
            my $object = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'argument to object-invocant must be a blessed reference' },
            ) unless blessed $object;

            return subname OBJECT_INVOCATION => sub {

                E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => 'object invocant expects at least a method argument' },
                ) unless @_;

                my ($method, @args) = @_;
                tail $object->$method(@args);
            };
        }),
        'class-invocant' => CLASS->wrap_function('class-invocant', { min => 1, max => 1 }, sub {
            my $class_from = shift;

            my $class = (
                blessed($class_from)                            ? blessed($class_from)
              : (defined($class_from) and not ref($class_from)) ? $class_from
              : E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => 'argument to class-invocant must be a blessed reference or class name' }
                )
            );

            return subname CLASS_INVOCATION => sub {

                E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => 'class invocant expects at least a method argument' },
                ) unless @_;

                my ($method, @args) = @_;
                tail $class->$method(@args);
            };
        }),
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Library::Data::Objects
All functionality related to objects

@SYNOPSIS

    ; object predicate
    (object? foo)

    ; determining the class name
    (class-of obj)

    ; testing is-a relationships
    (is-a? foo "MyClass")

    ; role testing
    (does? foo "MyRole")

    ; forcing object method call
    ((object-invocant Type) :foo)

    ; forcing class method call
    ((class-invocant "MyClass") :new)

@DESCRIPTION
This library contains the functionality necessary to introspect and handle !TAGGED<objects>.

=head1 PROVIDED FUNCTIONS

=head2 object?

    (object? <item> ...)

Tests if all arguments are objects.

=head2 class-of

    (class-of <object>)

Returns the name of the class of the object argument. This should only be used for
introspective and debugging purposes. If you want to know whether or not an object
conforms to a classes' interface use L</"is-a?">.

=head2 is-a?

    (is-a? <item> <class>)

Tests if the C<item> is-a C<class>. Will return an undefined value if it isn't, or 
if the C<item> is not an object.

=head2 does?

    (does? <item> <role>)

Tests if the C<item> implements the C<role>. Will return an undefined value if it
doesn't, or if the C<item> is not an object.

!TAG<roles>

=head2 object-invocant

    ((object-invocant <item>) <method> <arg> ...)

This will return a function accepting a method and method arguments to call on the
item as an object. This is mostly useful if you want to call type object
methods on L<types|Template::SX::Library::Types>, since they are special handled.

!TAG<object methods>
!TAG<type objects>

=head2 class-invocant

    ((class-invocant <class-or-object>) <method> <arg> ...)

Since L<Template::SX> does not allow strings to be used as applicants, this is 
currently the only way to call a class method. The interface works the same as in 
L</object-invocant>, but it will accept either an object or a class name.

!TAG<class methods>

=end fusion






=head1 NAME

Template::SX::Library::Data::Objects - All functionality related to objects

=head1 SYNOPSIS

    ; object predicate
    (object? foo)

    ; determining the class name
    (class-of obj)

    ; testing is-a relationships
    (is-a? foo "MyClass")

    ; role testing
    (does? foo "MyRole")

    ; forcing object method call
    ((object-invocant Type) :foo)

    ; forcing class method call
    ((class-invocant "MyClass") :new)

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Data::Objects

=over 2

=item *

L<Template::SX::Library>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This library contains the functionality necessary to introspect and handle objects.

=head1 PROVIDED FUNCTIONS

=head2 object?

    (object? <item> ...)

Tests if all arguments are objects.

=head2 class-of

    (class-of <object>)

Returns the name of the class of the object argument. This should only be used for
introspective and debugging purposes. If you want to know whether or not an object
conforms to a classes' interface use L</"is-a?">.

=head2 is-a?

    (is-a? <item> <class>)

Tests if the C<item> is-a C<class>. Will return an undefined value if it isn't, or 
if the C<item> is not an object.

=head2 does?

    (does? <item> <role>)

Tests if the C<item> implements the C<role>. Will return an undefined value if it
doesn't, or if the C<item> is not an object.

=head2 object-invocant

    ((object-invocant <item>) <method> <arg> ...)

This will return a function accepting a method and method arguments to call on the
item as an object. This is mostly useful if you want to call type object
methods on L<types|Template::SX::Library::Types>, since they are special handled.

=head2 class-invocant

    ((class-invocant <class-or-object>) <method> <arg> ...)

Since L<Template::SX> does not allow strings to be used as applicants, this is 
currently the only way to call a class method. The interface works the same as in 
L</object-invocant>, but it will accept either an object or a class name.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Template::SX::Library::Data::Objects> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut