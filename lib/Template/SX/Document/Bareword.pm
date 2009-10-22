use MooseX::Declare;

class Template::SX::Document::Bareword 
    extends Template::SX::Document::Value {

    use Data::Dump           qw( pp );
    use MooseX::Types::Moose qw( Str );

    has '+value' => (isa => Str);

    method is_dot { $self->value eq '.' }

    method compile_functional (Object $inf) {
        
        return $inf->render_call(
            method  => 'make_getter',
            args    => {
                name        => pp($self->value),
                location    => pp($self->location),
            },
        );
    }

    method compile_structural (Object $inf) {

        return $inf->render_call(
            method  => 'make_object_builder',
            args    => {
                class       => pp('Template::SX::Runtime::Bareword'),
                arguments   => sprintf(
                    '{ value => %s, cached_by => q(value) }', pp($self->value),
                ),
            },
        );
    }
}
