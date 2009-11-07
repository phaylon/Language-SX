use MooseX::Declare;

class Template::SX::Document::Cell 
    extends Template::SX::Document::Container 
    with    Template::SX::Document::Locatable {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );
    use Data::Dump              qw( pp );

    my @Pairs     = qw/ ( ) [ ] { } /;
    my %OpenerFor = reverse @Pairs;
    my %CloserFor = @Pairs;
    my %Name      = qw/ ( normal ) normal [ square ] square { curly } curly /;

    Class::MOP::load_class($_)
        for E_SYNTAX, E_END_OF_STREAM;

    method compile (Object $inf, Scope $scope) {

        my $method = "compile_$scope";
        return $self->$method($inf);
    }

    method compile_functional { 'FUNCT CELL' }

    method _compile_structural_template (Object $inf, Object $item, CodeRef $collect) {

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

    method compile_structural (Object $inf) {

        my @args;
        my $collector = sub {
            push @args, shift @_;
            return sprintf '@{ $_[%d] }', $#args;
        };

        my $template = sprintf(
            'sub { my @res = (%s); $res[0] }',
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
    }

    method _is_closing (Str $value) {
        return defined $OpenerFor{ $value };
    }

    method _closer_for (Str $value) {
        return $CloserFor{ $value };
    }

    method new_from_stream (
        ClassName $class: 
            Object   $doc, 
            Object   $stream, 
            Str      $value,
            Location $loc
    ) {
        
        my $self = $class->new_from_value($value, $loc);

        while (my $token = $stream->next_token) {
            my ($token_type, $token_value, $token_location) = @$token;

            if ($self->_is_closing($token->[1])) {

                if ($self->_closer_for($value) eq $token->[1]) {

                    if (my $head = $self->head_node) {

                        return undef
                            if $head->isa('Template::SX::Document::Bareword')
                                and $head->value eq '#';
                    }

                    return $self;
                }
                else {

                    E_SYNTAX->throw(
                        message  => sprintf(
                            q(expected cell to be closed with '%s' (%s), not '%s' (%s)), 
                            $CloserFor{ $value }, 
                            $Name{ $value },
                            $token->[1],
                            $Name{ $token->[1] },
                        ),
                        location => $token_location,
                    );
                }
            }

            my $node = $doc->new_node_from_stream($stream, $token);

            $self->add_node($node) 
                if defined $node;
        }

        E_END_OF_STREAM->throw(
            location => $loc,
            message  => 'unexpected end of stream before cell was closed',
        );
    }

    method new_from_value (ClassName $class: Str $value, Location $loc) {

        my $specific_class = $class->_find_class($value)
            or E_SYNTAX->throw(
                location    => $loc,
                message     => sprintf(q(invalid cell opener '%s'), $value),
            );

        Class::MOP::load_class($specific_class);
        return $specific_class->new(location => $loc);
    }

    method _find_class (ClassName $class: Str $value) {

        my $specific_class = (

              $value eq CELL_APPLICATION    ? 'Application'
            : $value eq CELL_ARRAY          ? 'Application'
            : $value eq CELL_HASH           ? 'Hash'
            : undef
        );

        return undef
            unless $specific_class;

        return join '::', __PACKAGE__, $specific_class;
    }
}
