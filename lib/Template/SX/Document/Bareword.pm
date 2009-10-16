use MooseX::Declare;

class Template::SX::Document::Bareword 
    extends Template::SX::Document::Value {

    use Data::Dump           qw( pp );
    use MooseX::Types::Moose qw( Str );

    has '+value' => (isa => Str);

    method compile_functional (Object $inf) {
        
        return $inf->render_call(
            method  => 'make_getter',
            args    => {
                name    => pp($self->value),
            },
        );
    }
}
