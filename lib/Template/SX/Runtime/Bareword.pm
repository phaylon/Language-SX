use MooseX::Declare;

class Template::SX::Runtime::Bareword is dirty {

    use MooseX::Types::Moose qw( Str );

    clean;
    use overload '""' => 'as_string', fallback => 1;

    has value => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );

    method as_string (Any @) { $self->value }
}
