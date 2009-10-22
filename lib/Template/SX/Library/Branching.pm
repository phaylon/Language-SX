use MooseX::Declare;

class Template::SX::Library::Branching extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Template::SX::Constants qw( :all );
    Class::MOP::load_class(E_SYNTAX);

    class_has '+syntax_map';
    class_has '+function_map';

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

        return sub {

            if ($condition->(@_)) {
                return $consequence->(@_);
            }
            elsif ($alternative) {
                return $alternative->(@_);
            }
            else {
                return undef;
            }
        };
    }
}

