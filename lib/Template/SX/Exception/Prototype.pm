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

    method rethrow { die $self }

    method throw_at (Location $loc) {

        Class::MOP::load_class($self->class);
        $self->class->throw(%{ $self->attributes }, location => $loc);
    }

    sub as_string { $_[0]->attributes->{message} }
}
