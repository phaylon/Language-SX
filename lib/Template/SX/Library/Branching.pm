use MooseX::Declare;

class Template::SX::Library::Branching extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Call::Tail;
    use Sub::Name                   qw( subname );
    use TryCatch;
    use Data::Dump                  qw( pp );
    use Template::SX::Constants     qw( :all );
    use Template::SX::Util          qw) :all );
    use MooseX::Types::Structured   qw( Tuple );
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

                my $lex_inf = $inf->with_new_lexical_collector;
                my $body    = $lex_inf->with_lexicals('_')->render_sequence([$conseq]);

                require Template::SX::Inflator::Precompiled;
                $conseq = Template::SX::Inflator::Precompiled->new(
                    location    => $op->location,
                    compiled    => $inf->render_call(
                        library => 'Template::SX::Library::ScopeHandling',
                        method  => 'make_lambda_generator',
                        args    => {
                            sequence    => $body,
                            bind        => pp([$lex_inf->collected_lexicals]),
                            inf         => '$inf',
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

    method make_cond_branch (ArrayRef[ArrayRef] :$clauses!) {

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

    my $BuildIfElse = sub {
        my ($name, $test_false) = @_;

        return sub {
            my $self = shift;
            my $inf  = shift;
            my $cell = shift;

            E_SYNTAX->throw(
                message     => sprintf('%s condition expects 2 or 3 arguments, not %d', $name, scalar @_),
                location    => $cell->location,
            ) unless @_ >= 2 and @_ <= 3;

            my ($condition, $consequence, $alternative) = @_;

            return $inf->render_call(
                library => $CLASS,
                method  => 'make_if_else_branch',
                args    => {
                    condition   => $condition->compile($inf, SCOPE_FUNCTIONAL),
                    consequence => $consequence->compile($inf, SCOPE_FUNCTIONAL),
                    test_false  => ($test_false ? 1 : 0),
                  ( $alternative 
                    ? ( alternative => $alternative->compile($inf, SCOPE_FUNCTIONAL) )
                    : () ),
                },
            );
        };
    };

    CLASS->add_syntax(
        if      => $BuildIfElse->('if'),
        unless  => $BuildIfElse->('unless', 1),
    );

    method make_if_else_branch (CodeRef :$condition!, CodeRef :$consequence!, CodeRef :$alternative?, Bool :$test_false?) {

        my $name = ( $test_false ? 'UNLESS_ELSE_BRANCH' : 'IF_ELSE_BRANCH' );
        my $test = sub { $test_false ? not($condition->(@_)) : goto $condition };

        return subname $name => sub {

            if ($test->(@_)) {
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

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Library::Branching
Branching and conditional functionality

@method make_cond_branch
%param :$clauses List of C<(type, condition, consequence, location)> tuples.
Will return a callback for the condition specifications. C<type> can be either
C<return> or C<apply>. If it is C<apply> then the value calculated by C<condition>
will be passed as argument to the C<consequence>, which is then expected to be a
code reference. If the C<type> is C<return> the return value of the C<condition>
will be thrown away and the result of the C<consequence> will be returned.

@method make_if_else_branch
%param :$condition      The condition callback to test for.
%param :$consequence    The consequence callback if the test returned true.
%param :$alternative    An optional alternative if the test returned false.
This will evaluate the C<$condition> and if its true return the result of an
evaluation of the C<$consequence>. If it was false it will either return an
undefiend value or the return value of the C<$alternative> if one was specified.

@SYNOPSIS

    ; multiple branching
    (cond [(< n 0) "negative"]
          [(> n 0) "positive"]
          [#t      "zero])

    ; positive binary branch
    (if (even? foo)
      "foo is even"
      "foo is odd")

    ; negative binary branch
    (unless (even? foo)
      "foo is odd"
      "foo is even")

@DESCRIPTION

This library contains functionality related to branching and conditional evaluation.

!TAG<conditionals>

=head1 PROVIDED SYNTAX ELEMENTS

=head2 cond

    (cond (<test> <consequence>)
          (<test> => <applicant>)
          (<test> -> <expression-with-_>)
          ...)

This is a very simple form of a switch/case implementation. Let me give an example
first:

    (define (identify-number n)
      (cond [(< n 0) :negative]
            [(> n 0) :positive]
            [#t      :zero]))

    (identify-number 23)    ; positive
    (identify-number -7)    ; negative
    (identify-number 0)     ; zero

C<cond> will try each specified clause in turn. It will evaluate the C<test> condition
until one returns true. In the simplest form with one other expression in the clause,
the actual value returned by the C<test> will be thrown away and the return value of
the other expression will be returned.

If you want to add a default clause, you can simply put a true boolean in the C<test>
position as in the example above. It will always return true, and C<cond> will always
return the consequential value. You should always have these at the end, since clauses
following them will never be evaluated.

While this is all very useful, sometimes you I<do> want to do something with the value
that was calculatd by the C<test> condition. Imagine the following scenario:

    (define (get-item-links obj)
      (cond [(obj :find-custom-links)   => append]
            [(obj :find-default-links)  => (-> (map _ absolute-uri))]
            [(obj :error-handler)       => (-> (_ "no links could be found"))]
            [#t (error "no links could be found")]))

This will first see if the C<obj> returns something when the C<find_custom_links> method
is called. If it does, it will pass the found value to L<Template::SX::Library::Lists/append>
which will essentially copy it one level down. If nothing was found, the next clause will
test C<find_default_links> in the same way. If something is found, it will be mapped through
a fictional function named C<absolute-uri>. If this method also didn't return anything, it
will try to locate an C<error_handler> on the object that if found will be called with a
suitable error message. The default clause just dies violently.

This is already an improvement over how it would look if we didn't use C<=E<gt>>. But if you
take a look at the second clause again:

    [(obj :find-default-links) => (-> (map _ absolute-uri))]

you might think that always writing C< =E<gt> (-E<gt> > can get annoying after a while, and
you're right. That's why there is a very simple special case when you use C<-E<gt>> directly
instead of C<=E<gt>>:
    
    [(obj :find-default-links) -> (map _ absolute-uri)]

This is the same as the above, but it might look a bit less trippy to some.

=head2 if

    (if <condition> <consequence>)
    (if <condition> <consequence> <alternative>)

This works just as you probably expect: If the C<condition> evaluates to a true value, the
C<consequence> will be evaluated and the resulting value returned. If the C<condition>
evaluated to a false value, it will either return an undefined value or the result of an
evaluation of the C<alternative>, if one was specified.

=head2 unless

    (unless <condition> <consequence>)
    (unless <condition> <consequence> <alternative>)

Just like L</if> but the other way around. It will evaluate the C<consequence> if the
C<condition> is I<false>, and the C<alternative> (or return undefined) otherwise.

=end fusion






=head1 NAME

Template::SX::Library::Branching - Branching and conditional functionality

=head1 SYNOPSIS

    ; multiple branching
    (cond [(< n 0) "negative"]
          [(> n 0) "positive"]
          [#t      "zero])

    ; positive binary branch
    (if (even? foo)
      "foo is even"
      "foo is odd")

    ; negative binary branch
    (unless (even? foo)
      "foo is odd"
      "foo is even")

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Branching

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

This library contains functionality related to branching and conditional evaluation.

=head1 PROVIDED SYNTAX ELEMENTS

=head2 cond

    (cond (<test> <consequence>)
          (<test> => <applicant>)
          (<test> -> <expression-with-_>)
          ...)

This is a very simple form of a switch/case implementation. Let me give an example
first:

    (define (identify-number n)
      (cond [(< n 0) :negative]
            [(> n 0) :positive]
            [#t      :zero]))

    (identify-number 23)    ; positive
    (identify-number -7)    ; negative
    (identify-number 0)     ; zero

C<cond> will try each specified clause in turn. It will evaluate the C<test> condition
until one returns true. In the simplest form with one other expression in the clause,
the actual value returned by the C<test> will be thrown away and the return value of
the other expression will be returned.

If you want to add a default clause, you can simply put a true boolean in the C<test>
position as in the example above. It will always return true, and C<cond> will always
return the consequential value. You should always have these at the end, since clauses
following them will never be evaluated.

While this is all very useful, sometimes you I<do> want to do something with the value
that was calculatd by the C<test> condition. Imagine the following scenario:

    (define (get-item-links obj)
      (cond [(obj :find-custom-links)   => append]
            [(obj :find-default-links)  => (-> (map _ absolute-uri))]
            [(obj :error-handler)       => (-> (_ "no links could be found"))]
            [#t (error "no links could be found")]))

This will first see if the C<obj> returns something when the C<find_custom_links> method
is called. If it does, it will pass the found value to L<Template::SX::Library::Lists/append>
which will essentially copy it one level down. If nothing was found, the next clause will
test C<find_default_links> in the same way. If something is found, it will be mapped through
a fictional function named C<absolute-uri>. If this method also didn't return anything, it
will try to locate an C<error_handler> on the object that if found will be called with a
suitable error message. The default clause just dies violently.

This is already an improvement over how it would look if we didn't use C<=E<gt>>. But if you
take a look at the second clause again:

    [(obj :find-default-links) => (-> (map _ absolute-uri))]

you might think that always writing C< =E<gt> (-E<gt> > can get annoying after a while, and
you're right. That's why there is a very simple special case when you use C<-E<gt>> directly
instead of C<=E<gt>>:
    
    [(obj :find-default-links) -> (map _ absolute-uri)]

This is the same as the above, but it might look a bit less trippy to some.

=head2 if

    (if <condition> <consequence>)
    (if <condition> <consequence> <alternative>)

This works just as you probably expect: If the C<condition> evaluates to a true value, the
C<consequence> will be evaluated and the resulting value returned. If the C<condition>
evaluated to a false value, it will either return an undefined value or the result of an
evaluation of the C<alternative>, if one was specified.

=head2 unless

    (unless <condition> <consequence>)
    (unless <condition> <consequence> <alternative>)

Just like L</if> but the other way around. It will evaluate the C<consequence> if the
C<condition> is I<false>, and the C<alternative> (or return undefined) otherwise.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 make_cond_branch

    ->make_cond_branch(ArrayRef[ArrayRef] :$clauses!)

=over

=item * Named Parameters:

=over

=item * ArrayRef[ArrayRef] C<:$clauses>

List of C<(type, condition, consequence, location)> tuples.

=back

=back

Will return a callback for the condition specifications. C<type> can be either
C<return> or C<apply>. If it is C<apply> then the value calculated by C<condition>
will be passed as argument to the C<consequence>, which is then expected to be a
code reference. If the C<type> is C<return> the return value of the C<condition>
will be thrown away and the result of the C<consequence> will be returned.

=head2 make_if_else_branch

    ->make_if_else_branch(
        CodeRef :$condition!,
        CodeRef :$consequence!,
        CodeRef :$alternative,
        Bool :$test_false
    )

=over

=item * Named Parameters:

=over

=item * CodeRef C<:$alternative> (optional)

An optional alternative if the test returned false.

=item * CodeRef C<:$condition>

The condition callback to test for.

=item * CodeRef C<:$consequence>

The consequence callback if the test returned true.

=item * Bool C<:$test_false> (optional)

=back

=back

This will evaluate the C<$condition> and if its true return the result of an
evaluation of the C<$consequence>. If it was false it will either return an
undefiend value or the return value of the C<$alternative> if one was specified.

=head2 meta

Returns the meta object for C<Template::SX::Library::Branching> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut