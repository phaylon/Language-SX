use MooseX::Declare;

class Template::SX::Document::Cell::Application 
    extends Template::SX::Document::Cell {

    use Template::SX::Constants qw( :all );

    method _try_compiling_as_syntax (Object $inf, Object $node, ArrayRef[Object] $args) {

        return undef 
            unless $node->isa('Template::SX::Document::Bareword');

        return $inf->compile_syntax($node->value, $args)
            if $inf->has_syntax_compiler($node->value);

        return undef;
    }

    method compile_functional (Object $inf) {

        # FIXME throw exception
        unless ($self->node_count) {
            die "Empty application is illegal. For empty array references use [] instead\n";
        }

        my $apply = $self->head_node;
        my @args  = $self->tail_nodes;

        # syntax special case
     #   if (defined( my $syntax = $self->_try_compiling_as_syntax($inf, $apply, \@args) )) {
     #       return $syntax;
     #   }

        # normal application
        return $inf->render_call(
            method  => 'make_application',
            args    => {
                apply       => $apply->compile($inf, SCOPE_FUNCTIONAL),
                arguments   => sprintf(
                    '[%s]',
                    join(', ',
                        map {
                            $_->compile($inf, SCOPE_FUNCTIONAL);
                        } @args
                    ),
                ),
            },
        );
    }
}
