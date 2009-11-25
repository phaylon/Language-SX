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

    method make_not_operator (ArrayRef[CodeRef] :$elements!, Bool :$test_definition) {

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
        'begin'     => sub {
            my ($self, $inf, $cell, @seq) = @_;
            return $inf->render_sequence(\@seq);
        },
    );

    method _check_min_args (Str $who, Int $expects, Object $cell, ArrayRef[Object] $args) {

        my $arg = $expects == 1 ? 'argument' : 'arguments';

        E_SYNTAX->throw(
            message     => "the '$who' operator requires at least $expects $arg, but only got " . scalar(@$args),
            location    => $cell->location,
        ) unless @$args >= $expects;
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Library::Operators
All functionality concerning operators

@method make_and_operator
%param :$elements           Sequence of expressions.
%param :$test_definition    Test for definedness instead of truth.
Creates a callback for an L</and> combined operator sequence.

@method make_not_operator
%param :$elements           Sequence of expressions.
%param :$test_definition    Test for definedness instead of truth.
Creates a callback for a L</not> combined operator sequence.

@method make_or_operator
%param :$elements           Sequence of expressions.
%param :$test_definition    Test for definedness instead of truth.
Creates a callback for an L</or> combined operator sequence.

@SYNOPSIS

    ; return first true value
    (or foo bar baz)

    ; return last if all are true
    (and foo bar baz)

    ; return undef if one is true
    (not foo bar baz)

    ; return first defined value
    (or-def foo bar baz)

    ; return last if all are defined
    (and-def foo bar baz)

    ; return undef is one is defined
    (not foo bar baz)

    ; run all and return last value
    (begin foo bar baz)

@DESCRIPTION
This library contains all operators. These are short-circuiting syntax elements.
This means that in this scenario:

    (and 23 #f (error "foo"))

The C<error> call will never be made, since an earlier value was already false.

=head1 PROVIDED SYNTAX ELEMENTS

=head2 or

    (or <expr> <expr> ...)

This syntax element will evaluate each expression in turn and return the first
true value.

=head2 or-def

    (or-def <expr> <expr> ...)

Same as L</or> but it will return the first defined value.

=head2 and

    (and <expr> <expr> ...)

This syntax element will evaluate each expression in turn and return an undefined
value as soon as one expression evaluates to false. If all expressions evaluate to
true, the last value will be returned.

=head2 and-def

    (and-def <expr> <expr> ...)

Same as L</and> but it will return an undefined value when it comes across an
undefined return value from an expression.

=head2 not

    (not <expr> ...)

This syntax element will evaluate each expression in turn and return an undefined
value as soon as it encounters a true return value. If all expressions evaluated
to false it will return C<1>.

=head2 not-def

    (not-def <expr> ...)

Same as L</not> but it will return an undefined value as soon as one of the 
expressions evaluates to a defined value.

=head2 begin

    (begin <expr> ...)

This will simply evaluate all expressions in sequence and return the last one's
return value. This is useful for performing multiple operations in one expression
like L<Template::SX::Library::ScopeHandling/lambda> does. This is especially useful
for constructs that would otherwise only take one expression or value as argument:

    (if (empty? foo)
      #f
      (begin
        (do-something-with foo)
        bar))

=end fusion






=head1 NAME

Template::SX::Library::Operators - All functionality concerning operators

=head1 SYNOPSIS

    ; return first true value
    (or foo bar baz)

    ; return last if all are true
    (and foo bar baz)

    ; return undef if one is true
    (not foo bar baz)

    ; return first defined value
    (or-def foo bar baz)

    ; return last if all are defined
    (and-def foo bar baz)

    ; return undef is one is defined
    (not foo bar baz)

    ; run all and return last value
    (begin foo bar baz)

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Operators

=over 2

=item *

L<Template::SX::Library>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This library contains all operators. These are short-circuiting syntax elements.
This means that in this scenario:

    (and 23 #f (error "foo"))

The C<error> call will never be made, since an earlier value was already false.

=head1 PROVIDED SYNTAX ELEMENTS

=head2 or

    (or <expr> <expr> ...)

This syntax element will evaluate each expression in turn and return the first
true value.

=head2 or-def

    (or-def <expr> <expr> ...)

Same as L</or> but it will return the first defined value.

=head2 and

    (and <expr> <expr> ...)

This syntax element will evaluate each expression in turn and return an undefined
value as soon as one expression evaluates to false. If all expressions evaluate to
true, the last value will be returned.

=head2 and-def

    (and-def <expr> <expr> ...)

Same as L</and> but it will return an undefined value when it comes across an
undefined return value from an expression.

=head2 not

    (not <expr> ...)

This syntax element will evaluate each expression in turn and return an undefined
value as soon as it encounters a true return value. If all expressions evaluated
to false it will return C<1>.

=head2 not-def

    (not-def <expr> ...)

Same as L</not> but it will return an undefined value as soon as one of the 
expressions evaluates to a defined value.

=head2 begin

    (begin <expr> ...)

This will simply evaluate all expressions in sequence and return the last one's
return value. This is useful for performing multiple operations in one expression
like L<Template::SX::Library::ScopeHandling/lambda> does. This is especially useful
for constructs that would otherwise only take one expression or value as argument:

    (if (empty? foo)
      #f
      (begin
        (do-something-with foo)
        bar))

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 make_and_operator

    ->make_and_operator(
        ArrayRef[
            CodeRef
        ] :$elements!,
        Bool :$test_definition
    )

=over

=item * Named Parameters:

=over

=item * ArrayRef[CodeRef] C<:$elements>

Sequence of expressions.

=item * Bool C<:$test_definition> (optional)

Test for definedness instead of truth.

=back

=back

Creates a callback for an L</and> combined operator sequence.

=head2 make_not_operator

    ->make_not_operator(
        ArrayRef[
            CodeRef
        ] :$elements!,
        Bool :$test_definition
    )

=over

=item * Named Parameters:

=over

=item * ArrayRef[CodeRef] C<:$elements>

Sequence of expressions.

=item * Bool C<:$test_definition> (optional)

Test for definedness instead of truth.

=back

=back

Creates a callback for a L</not> combined operator sequence.

=head2 make_or_operator

    ->make_or_operator(
        ArrayRef[
            CodeRef
        ] :$elements!,
        Bool :$test_definition
    )

=over

=item * Named Parameters:

=over

=item * ArrayRef[CodeRef] C<:$elements>

Sequence of expressions.

=item * Bool C<:$test_definition> (optional)

Test for definedness instead of truth.

=back

=back

Creates a callback for an L</or> combined operator sequence.

=head2 meta

Returns the meta object for C<Template::SX::Library::Operators> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut