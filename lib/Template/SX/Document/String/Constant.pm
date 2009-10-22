use MooseX::Declare;

class Template::SX::Document::String::Constant 
    extends Template::SX::Document::Value {

    use Data::Dump           qw( pp );
    use Template::SX::Types  qw( Scope );

    method compile (Object $inf, Scope $scope) {

        return $inf->render_call(
            method  => 'make_constant',
            args    => {
                value   => pp($self->value),
            },
        );
    }
}
