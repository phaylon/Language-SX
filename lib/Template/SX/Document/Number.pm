use MooseX::Declare;

class Template::SX::Document::Number
    extends Template::SX::Document::Value {

    use Template::SX::Types  qw( Scope );
    use MooseX::Types::Moose qw( Num );

    has '+value' => (isa => Num);

    method compile (Object $inf, Scope $scope) {

        return $inf->render_call(
            method  => 'make_constant',
            args    => {
                value   => $self->value,
            },
        );
    }
}

