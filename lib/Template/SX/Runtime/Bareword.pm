use MooseX::Declare;

class Template::SX::Runtime::Bareword {
    use overload '""' => 'as_string', fallback => 1;

    use MooseX::Types::Moose qw( Str );

    has value => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );

    method as_string { $self->value }
}
