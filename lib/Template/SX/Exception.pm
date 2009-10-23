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

    method rethrow { die $self }

    sub as_string { 
        my $self = shift;
        return $self->format_message;
    }

    method format_message {
        
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

    __PACKAGE__->meta->make_immutable(inline_constructor => 0);
}

1;
