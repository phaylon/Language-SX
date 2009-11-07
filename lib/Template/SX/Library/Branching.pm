use MooseX::Declare;

class Template::SX::Library::Branching extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Call::Tail;
    use Sub::Name               qw( subname );
    use TryCatch;
    use Data::Dump              qw( pp );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw) :all );
    Class::MOP::load_class(E_SYNTAX);

    class_has '+syntax_map';
    class_has '+function_map';

    CLASS->add_syntax(cond => sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        E_SYNTAX->throw(
            message     => 'cond branching requires at least one clause',
            location    => $cell->location,
        ) unless @_;

        $inf->render_call(
            library => $CLASS,
            method  => 'make_cond_branch',
            args    => {
                clauses     => sprintf(
                    '[%s]',
                    join(
                        ', ',
                        map { $self->_compile_cond_clause($inf, $_) } @_
                    ),
                ),
            },
        );
    });

    method _compile_cond_clause (Object $inf, Object $clause) {

        E_SYNTAX->throw(
            message     => 'cond branching clause is expected to be a list',
            location    => $clause->location,
        ) unless $clause->isa('Template::SX::Document::Cell::Application');

        my ($type, $cond, $conseq);

        if ($clause->node_count == 2) {

            ($type, $cond, $conseq) = (return => $clause->all_nodes);
        }
        elsif ($clause->node_count == 3) {

            ($cond, my $op, $conseq) = ($clause->all_nodes);

            E_SYNTAX->throw(
                message     => 'operator option in cond branching clause is expected to be a bareword',
                location    => $op->location,
            ) unless $op->isa('Template::SX::Document::Bareword');

            if ($op->value eq '=>') {
                $type = 'apply';
            }
            elsif ($op->value eq '->') {
                $type = 'apply';

                require Template::SX::Inflator::Precompiled;
                $conseq = Template::SX::Inflator::Precompiled->new(
                    location    => $op->location,
                    compiled    => $inf->render_call(
                        library => 'Template::SX::Library::ScopeHandling',
                        method  => 'make_lambda_generator',
                        args    => {
                            sequence    => $inf->with_lexicals('_')->render_sequence([$conseq]),
                            has_max     => 1,
                            has_min     => 1,
                            max         => 1,
                            min         => 1,
                            positionals => '[qw( _ )]',
                        },
                    ),
                );
            }
            else {
                E_SYNTAX->throw(
                    message     => sprintf(q(invalid application operator in cond branching clause: '%s'), $op->value),
                    location    => $op->location,
                );
            }
        }
        else {
            E_SYNTAX->throw(
                message     => 'cond branching clause has to be in form (cond conseq) or (cond op conseq)',
                location    => $clause->location,
            );
        }

        return sprintf(
            '[%s, %s, %s, %s]',
            pp($type),
          ( map { $_->compile($inf, SCOPE_FUNCTIONAL) } 
            $cond, $conseq ),
            pp($conseq->location),
        );
    }

    method make_cond_branch (ArrayRef[ArrayRef] :$clauses) {

        return subname COND_BRANCH => sub {
            my $env = shift;

          CLAUSE:
            for my $clause (@$clauses) {

                my $value = $clause->[1]->($env)
                    or next CLAUSE;

                my $conseq = $clause->[2]->($env);

                if ($clause->[0] eq 'return') {

                    return $conseq;
                }
                elsif ($clause->[0] eq 'apply') {

                    my $res;

                    try {
                        $res = apply_scalar 
                            apply       => $conseq,
                            arguments   => [$value];
                    }
                    catch (Template::SX::Exception::Prototype $e) {
                        $e->throw_at($clause->[3]);
                    }

                    return $res;
                }
            }

            return undef;
        };
    }

    CLASS->add_syntax(if => sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        E_SYNTAX->throw(
            message     => sprintf('if condition expects 2 or 3 arguments, not %d', scalar @_),
            location    => $cell->location,
        ) unless @_ >= 2 and @_ <= 3;

        my ($condition, $consequence, $alternative) = @_;

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_if_else_branch',
            args    => {
                condition   => $condition->compile($inf, SCOPE_FUNCTIONAL),
                consequence => $consequence->compile($inf, SCOPE_FUNCTIONAL),
              ( $alternative 
                ? ( alternative => $alternative->compile($inf, SCOPE_FUNCTIONAL) )
                : () ),
            },
        );
    });

    method make_if_else_branch (CodeRef :$condition, CodeRef :$consequence, CodeRef :$alternative?) {

        return subname IF_ELSE_BRANCH => sub {

            if ($condition->(@_)) {
                goto $consequence;
#                return $consequence->(@_);
            }
            elsif ($alternative) {
                goto $alternative;
#                return $alternative->(@_);
            }
            else {
                return undef;
            }
        };
    }
}

