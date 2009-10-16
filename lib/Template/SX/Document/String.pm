use MooseX::Declare;

class Template::SX::Document::String
    extends Template::SX::Document::Value {

    use MooseX::Types::Moose qw( Str );

    has '+value' => (isa => Str);
}


