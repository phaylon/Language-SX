use MooseX::Declare;

class Template::SX::Document::Cell::Hash
    extends Template::SX::Document::Cell {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );

    Class::MOP::load_class($_)
        for E_SYNTAX;

    method compile_functional (Object $inf) {
        
        E_SYNTAX->throw(
            message     => 'hash creation in functional mode requires even number of items',
            location    => $self->location,
        ) if $self->node_count % 2;

        return $inf->render_call(
            method  => 'make_hash_builder',
            args    => {
                items => sprintf(
                    '[%s]', join(
                        ', ',
                        map { $_->compile($inf, SCOPE_FUNCTIONAL) } $self->all_nodes,
                    ),
                ),
            },
        );
    }

    method __former_compile_structural (Object $inf) {

        return $inf->render_call(
            method  => 'make_hash_builder',
            args    => {
                items => sprintf(
                    '[%s]', join(
                        ', ',
                        map { $_->compile($inf, SCOPE_STRUCTURAL) } $self->all_nodes,
                    ),
                ),
            },
        );
    }
}

