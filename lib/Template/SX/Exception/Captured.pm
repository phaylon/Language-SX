use MooseX::Declare;

class Template::SX::Exception::Captured extends Template::SX::Exception {

    has captured => (
        is          => 'ro',
        required    => 1,
    );
}
