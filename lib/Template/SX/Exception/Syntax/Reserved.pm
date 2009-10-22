use MooseX::Declare;

class Template::SX::Exception::Syntax::Reserved 
    extends Template::SX::Exception::Syntax {

    use MooseX::Types::Moose qw( Str );

    has identifier => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );

    has library => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );
}
