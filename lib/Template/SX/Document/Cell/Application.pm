use MooseX::Declare;

class Template::SX::Document::Cell::Application 
    extends Template::SX::Document::Cell {

    use Data::Dump              qw( pp );
    use Perl6::Junction         qw( any );
    use Template::SX::Constants qw( :all );

    Class::MOP::load_class($_)
        for E_INTERNAL, E_SYNTAX;

    method _try_compiling_as_syntax (Object $inf, Object $node, ArrayRef[Object] $args) {

        return undef 
            unless $node->isa('Template::SX::Document::Bareword');

        return undef
            if $inf->known_lexical($node->value);

        if (my $syntax = $inf->find_library_syntax($node->value)) {
            return $inf->$syntax($self, @$args);
        }

        return undef;
    }

    method is_unquote (Object $inf) {

        my $node = $self->head_node
            or return undef;

        return undef
            unless $node->isa('Template::SX::Document::Bareword');

        return $node->value
            if $node->value eq any qw( unquote unquote-splicing );

        return undef;
    }

    method is_in_unquoting_state (Object $inf) {

        return undef
            if not $inf->quote_state 
               or $inf->quote_state ne QUOTE_QUASI
               or $self->node_count < 1;

        return 1;
    }

    method compile_structural (Object $inf) {

        if ($self->is_in_unquoting_state($inf) and (my $str = $self->is_unquote($inf))) {
            my ($identifier, @args) = $self->all_nodes;

            if (defined( my $syntax = $self->_try_compiling_as_syntax($inf, $identifier, \@args) )) {
                return $syntax;
            }
            else {
                E_INTERNAL->throw(
                    message     => "no syntax handler found for '$str' unquotes",
                    location    => $identifier->location,
                );
            }
        }

        return $inf->render_call(
            method  => 'make_list_builder',
            args    => {
                items   => sprintf(
                    '[%s]', join(
                        ', ',
                        # list context to allow for spliced unquoting
                        map { ($_->compile($inf, SCOPE_STRUCTURAL)) } $self->all_nodes,
                    ),
                ),
            },
        );
    }

    method compile_functional (Object $inf) {

        unless ($self->node_count) {
            
            E_SYNTAX->throw(
                location    => $self->location,
                message     => q{empty application is illegal; use '() for empty list},
            );
        }

        my $apply = $self->head_node;
        my @args  = $self->tail_nodes;

        # syntax special case
        if (defined( my $syntax = $self->_try_compiling_as_syntax($inf, $apply, \@args) )) {
            return $syntax;
        }

        # normal application
        return $inf->render_call(
            method  => 'make_application',
            args    => {
                apply       => $apply->compile($inf, SCOPE_FUNCTIONAL),
                location    => pp($self->location),
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
