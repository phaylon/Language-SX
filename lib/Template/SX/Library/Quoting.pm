use MooseX::Declare;

class Template::SX::Library::Quoting extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Data::Dump              qw( pp );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    Class::MOP::load_class($_)
        for E_SYNTAX, E_TYPE;
    
    class_has '+function_map';
    class_has '+syntax_map';

    method additional_inflator_traits {
        'QuoteState';
    }

    CLASS->add_syntax(quote => sub {
        my $self = shift;
        return $self->_quote(QUOTE_FULL, @_);
    });

    CLASS->add_syntax(quasiquote => sub {
        my $self = shift;
        return $self->_quote(QUOTE_QUASI, @_);
    });

    CLASS->add_syntax(unquote => sub {
        my $self = shift;
        return $self->_unquote(@_);
    });

    CLASS->add_syntax('unquote-splicing' => sub {
        my $self = shift;
        my ($inf, $cell, $item) = @_;

        my $unquoted = $self->_unquote(@_);

        return $inf->render_call(
            library     => $CLASS,
            method      => 'make_unquote_splicer',
            args        => {
                splice      => $unquoted,
                location    => pp($item->location),
            },
        );
    });

    method make_unquote_splicer (CodeRef :$splice, Location :$location) {
        
        return sub {
            my $env = shift;
            my $val = $splice->($env);

            E_TYPE->throw(message => 'spliced element is not an array reference', location => $location)
                unless ref $val eq 'ARRAY';

            return @$val;
        };
    }

    method _unquote (Object $inf, Object $cell, @args) {

        E_SYNTAX->throw(message => 'only single item can be unquoted at a time', location => $cell->location)
            unless @args == 1;

        E_SYNTAX->throw(message => 'illegal unquote outside of quasi-quoted environment', location => $cell->location)
            unless $inf->quote_state;

        my $unquoted = $args[0];

        return $unquoted->compile($inf, SCOPE_STRUCTURAL)
            unless $inf->quote_state eq QUOTE_QUASI;

        my $new_inf = $inf->clone_without_quote_state;
        return $unquoted->compile($new_inf, SCOPE_FUNCTIONAL);
    }

    method _quote (QuoteState $state, Object $inf, Object $cell, @args) {

#        warn "QUOTING " . pp([ map "$_", $cell->all_nodes ]);

        E_SYNTAX->throw(message => 'only single item can be quoted at a time', location => $cell->location)
            unless @args == 1;

        my $quoted = $args[0];

        if ($state eq QUOTE_QUASI and $quoted->isa('Template::SX::Document::Cell::Application')) {

            if (my $unquote = $quoted->is_unquote($inf)) {

                E_SYNTAX->throw(
                    message     => 'unquote-splicing directly inside quasiquote is illegal',
                    location    => $quoted->location,
                ) if $unquote eq 'unquote-splicing';
            }
        }

        my $new_inf = $inf->clone_with_quote_state($state);
        return $quoted->compile($new_inf, SCOPE_STRUCTURAL);
    }
}
