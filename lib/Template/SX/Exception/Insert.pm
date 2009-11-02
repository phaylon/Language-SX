use MooseX::Declare;

class Template::SX::Exception::Insert extends Template::SX::Exception {

    use MooseX::Types::Path::Class qw( File );

    has path => (
        is          => 'ro',
        isa         => File,
        required    => 1,
    );
}
