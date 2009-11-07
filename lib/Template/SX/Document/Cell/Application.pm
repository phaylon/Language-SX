use MooseX::Declare;

class Template::SX::Document::Cell::Application 
    extends Template::SX::Document::Cell {

    use Data::Dump              qw( pp );
    use Perl6::Junction         qw( any );
    use Template::SX::Constants qw( :all );
    use Scalar::Util            qw( blessed );

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

        return undef unless $self->node_count;
        my $node = $self->get_node(0);

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

    # TODO remove
    method __former_compile_structural_template (Object $inf, Object $item, CodeRef $collect) {

        if ($item->isa('Template::SX::Document::Cell::Application')) {

            if ($item->is_in_unquoting_state($inf) and (my $str = $item->is_unquote($inf))) {
                my ($identifier, @args) = $item->all_nodes;

                if (defined( my $syntax = $item->_try_compiling_as_syntax($inf, $identifier, \@args) )) {
                    return $collect->($syntax);
                }
                else {
                    E_INTERNAL->throw(
                        message     => "no syntax handler found for '$str' unquotes",
                        location    => $identifier->location,
                    );
                }
            }

            my @item_templates = map { $self->_compile_structural_template($inf, $_, $collect) } $item->all_nodes;
            return sprintf '[%s]', join ', ', @item_templates;
        }
        elsif ($item->isa('Template::SX::Document::Cell::Hash')) {

            my @item_templates = map { $self->_compile_structural_template($inf, $_, $collect) } $item->all_nodes;
            return sprintf '+{%s}', join ', ', @item_templates;
        }
        else {

            return $collect->($item);
        }
    }

    # TODO remove
    method __former_compile_structural (Object $inf) {

        my @args;
        my $collector = sub {
            push @args, shift @_;
            return sprintf '@{ $_[%d] }', $#args;
        };

        my $template = sprintf(
            'sub { %s }',
            $self->_compile_structural_template($inf, $self, $collector),
        );

        return $inf->render_call(
            method  => 'make_structure_builder',
            args    => {
                template    => $template,
                values      => sprintf(
                    '[%s]', join(
                        ', ',
                        map { blessed($_) ? $_->compile($inf, SCOPE_STRUCTURAL) : $_ } @args
                    ),
                ),
            },
        );

#        if ($self->is_in_unquoting_state($inf) and (my $str = $self->is_unquote($inf))) {
#            my ($identifier, @args) = $self->all_nodes;
#
#            if (defined( my $syntax = $self->_try_compiling_as_syntax($inf, $identifier, \@args) )) {
#                return $syntax;
#            }
#            else {
#                E_INTERNAL->throw(
#                    message     => "no syntax handler found for '$str' unquotes",
#                    location    => $identifier->location,
#                );
#            }
#        }
#
#        return $inf->render_call(
#            method  => 'make_list_builder',
#            args    => {
#                items   => sprintf(
#                    '[%s]', join(
#                        ', ',
#                        # list context to allow for spliced unquoting
#                        map { ($_->compile($inf, SCOPE_STRUCTURAL)) } $self->all_nodes,
#                    ),
#                ),
#            },
#        );

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
