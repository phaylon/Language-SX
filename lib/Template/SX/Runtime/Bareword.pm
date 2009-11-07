use MooseX::Declare;

class Template::SX::Runtime::Bareword is dirty {

    use MooseX::Types::Moose qw( Str );

    clean;

    # inlined for speed optimisation
    use overload '""' => sub { (shift)->value }, fallback => 1;

    has value => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );
}
