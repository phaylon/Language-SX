use MooseX::Declare;

class Template::SX::Exception::UnboundVar
    extends Template::SX::Exception {

    use MooseX::Types::Moose qw( Str );

    has variable_name => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );
}
