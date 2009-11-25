use MooseX::Declare;

class Template::SX::Exception is dirty {

    use MooseX::Types::Moose    qw( Str );
    use Template::SX::Types     qw( Location );
    use Data::Dump              qw( pp );

    clean;
    use overload '""' => 'as_string', fallback => 1;

    has location => (
        is          => 'ro',
        isa         => Location,
        required    => 1,
        coerce      => 1,
    );

    has message => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );

    method throw (ClassName $class: @args) { 

        die $class->new(@args);
    }

    method rethrow () { die $self }

    sub as_string (@) {
        my $self = shift;
        return $self->format_message;
    }

    method format_message () {
        
        (my $type = ref $self) =~ s/^Template::SX:://;

        my $context = $self->location->{context};
        my $char    = $self->location->{char};

        $context =~ s/^(\s*)//;
        $char -= length $1;

        return sprintf "[%s] %s at %s line %d\n  %s\n  %s\n",
            $type,
            $self->message,
            $self->location->{source},
            $self->location->{line},
            $context,
            join('', ' ' x ($char - 1), '^');
    }

#    __PACKAGE__->meta->make_immutable(inline_constructor => 0);
}

1;

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Exception
Exception base class

@method as_string
Stringification method. Ignores all arguments so it can be a target for L<overload>.

@method format_message
Builds the complete formatted message string.

@method rethrow
Rethrows the exception. The exception will keep its original location.

@method throw
%param @args The constructor arguments.
Throws the exception.

@attr location
Where the exception was raised in the source.

@attr message
The actual message of the exception.

=end fusion






=head1 NAME

Template::SX::Exception - Exception base class

=head1 INHERITANCE

=over 2

=item *

Template::SX::Exception

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|/"location (required)"> attribute.

=item * message (B<required>)

Initial value for the L<message|/"message (required)"> attribute.

=back

=head2 as_string

Stringification method. Ignores all arguments so it can be a target for L<overload>.

=head2 format_message

    ->format_message()

=over

=back

Builds the complete formatted message string.

=head2 location

Reader for the L<location|/"location (required)"> attribute.

=head2 message

Reader for the L<message|/"message (required)"> attribute.

=head2 rethrow

    ->rethrow()

=over

=back

Rethrows the exception. The exception will keep its original location.

=head2 throw

    ->throw(ClassName $class: @args)

=over

=item * Positional Parameters:

=over

=item * C<@args>

The constructor arguments.

=back

=back

Throws the exception.

=head2 meta

Returns the meta object for C<Template::SX::Exception> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 location (required)

=over

=item * Type Constraint

L<Location|Template::SX::Types/Location>

=item * Constructor Argument

C<location>

=item * Associated Methods

L<location|/location>

=back

Where the exception was raised in the source.

=head2 message (required)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<message>

=item * Associated Methods

L<message|/message>

=back

The actual message of the exception.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut