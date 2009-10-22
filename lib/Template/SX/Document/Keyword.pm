use MooseX::Declare;

class Template::SX::Document::Keyword extends Template::SX::Document::Value {
    
    use Data::Dump qw( pp );
    use MooseX::Types::Moose qw( Bool );

    method compile (Object $inf, @) {

        return $inf->render_call(
            method  => 'make_keyword_constant',
            args    => { value => pp($self->value) },
        );
    }
}

