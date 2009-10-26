use MooseX::Declare;

class Template::SX::Library::Operators extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Name;
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_SYNTAX;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    method make_and_operator (ArrayRef[CodeRef] :$elements!, Bool :$test_definition) {

        return subname AND_OPERATOR => sub {
            my $env = shift;
            my $res;

            for my $element (@$elements) {

                $res = $element->($env);
                
                return undef
                    if $test_definition
                        ? not( defined $res )
                        : not( $res );
            }

            return $res;
        };
    }

    method make_or_operator (ArrayRef[CodeRef] :$elements!, Bool :$test_definition) {

        return subname OR_OPERATOR => sub {
            my $env = shift;

            for my $element (@$elements) {

                my $res = $element->($env);

                return $res
                    if $test_definition
                        ? defined( $res )
                        : $res;
            }

            return undef;
        };
    }

    method make_not_operator (ArrayRef[CodeRef] :$elements, Bool :$test_definition) {

        return subname NOT_OPERATOR => sub {
            my $env = shift;

            for my $element (@$elements) {

                my $res = $element->($env);
                
                return undef
                    if $test_definition
                        ? defined( $res )
                        : $res;
            }

            return 1;
        };
    }

    method _build_operator_renderer (ClassName $class: Str :$name, Int :$arg_count, Str :$gen?, Bool :$test_definition) {

        return sub {
            my $self = shift;
            my $inf  = shift;
            my $cell = shift;

            $self->_check_min_args($name, $arg_count, $cell, [@_]);

            return $inf->render_call(
                library => $CLASS,
                method  => join('_', 'make', ($gen ? $gen : $name), 'operator'),
                args    => {
                    test_definition => ( $test_definition ? 1 : 0 ),
                    elements        => sprintf(
                        '[%s]', join(
                            ', ',
                            map { $_->compile($inf, SCOPE_FUNCTIONAL) } @_
                        ),
                    ),
                },
            );
        },
    }

    CLASS->add_syntax(
        'and'       => CLASS->_build_operator_renderer(name => 'and', arg_count => 2),
        'or'        => CLASS->_build_operator_renderer(name => 'or',  arg_count => 2),
        'not'       => CLASS->_build_operator_renderer(name => 'not', arg_count => 1),
        'and-def'   => CLASS->_build_operator_renderer(name => 'and-def', gen => 'and', arg_count => 2, test_definition => 1),
        'or-def'    => CLASS->_build_operator_renderer(name => 'or-def',  gen => 'or',  arg_count => 2, test_definition => 1),
        'not-def'   => CLASS->_build_operator_renderer(name => 'not-def', gen => 'not', arg_count => 1, test_definition => 1),
    );

    method _check_min_args (Str $who, Int $expects, Object $cell, ArrayRef[Object] $args) {

        my $arg = $expects == 1 ? 'argument' : 'arguments';

        E_SYNTAX->throw(
            message     => "the '$who' operator requires at least $expects $arg, but only got " . scalar(@$args),
            location    => $cell->location,
        ) unless @$args >= $expects;
    }
}
