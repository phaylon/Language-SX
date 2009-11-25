use MooseX::Declare;

class Template::SX::Library::Data::Functions extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Call::Tail;
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );
    use Scalar::Util            qw( blessed );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_functions(apply => sub {
        my ($op, @args) = @_;

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => 'apply expects at least two arguments' },
        ) unless @_ >= 2;

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => 'last argument to apply has to be a list' },
        ) unless ref $args[-1] eq 'ARRAY';

        push @args, @{ pop @args };
        tail apply_scalar(apply => $op, arguments => \@args);
    });

    CLASS->add_functions(
        'apply/list' => CLASS->wrap_function('apply/list', { min => 2, types => [qw( applicant )], }, sub {
            my ($apply, @args) = @_;

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'last argument to apply/list has to be a list' },
            ) unless ref $args[-1] eq 'ARRAY';

            push @args, @{ pop @args };
            tail apply_scalar(apply => $apply, arguments => \@args, to_list => 1);
        }),
    );

    CLASS->add_functions(
        while => CLASS->wrap_function('while', { min => 3, max => 3, types => [qw( lambda lambda applicant )] }, sub {
            my ($get, $test, $apply) = @_;

            my $value;
            while ($test->(my $next = $get->())) {
                apply_scalar apply => $apply, arguments => [$next];
                $value = $next;
            }

            return $value;
        }),
    );

    CLASS->add_functions(
        curry => CLASS->wrap_function('curry', { min => 2, types => [qw( applicant )] }, sub {
            my ($apply, @args) = @_;
            return sub {
                tail apply_scalar(
                    apply       => $apply,
                    arguments   => [@args, @_],
                );
            };
        }),
        rcurry => CLASS->wrap_function('rcurry', { min => 2, types => [qw( applicant )] }, sub {
            my ($apply, @args) = @_;
            return sub {
                tail apply_scalar(
                    apply       => $apply,
                    arguments   => [@_, @args],
                );
            };
        }),
        'rev-curry' => CLASS->wrap_function('rev-curry', { min => 1, max => 1, types => [qw( lambda )] }, sub {
            my ($lambda) = @_;
            return sub { @_ = reverse @_; goto $lambda };
        }),
    );

    CLASS->add_functions('lambda?', sub {

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => 'lambda predicate expects at least one argument' },
        ) unless @_;

        return scalar( grep { ref $_ ne 'CODE' } @_ ) ? undef : 1;
    });

    CLASS->add_functions('cascade', sub {

        return undef unless @_;

        my $value = shift @_;

        for my $idx (0 .. $#_) {
            my $apply = $_[ $idx ];

            return undef unless defined $value;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => sprintf 'cascade argument %s is not a valid applicant', $idx + 1 },
            ) unless blessed($apply) or ref $apply eq 'CODE';

            $value = apply_scalar apply => $apply, arguments => [$value];
        }

        return $value;
    });
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Library::Data
@see_also Template::SX::Library::ScopeHandling
@license  Template::SX

@class Template::SX::Library::Data::Functions
This library contains all functionality regarded to functions and application.

@SYNOPSIS

    ; applying with variable arguments
    (apply + 1 2 `(3 4))

    ; applying in list context
    (apply/list something 1 2 `(3 4))

    ; iterative calling
    (while 
      (<- (resultset :next))        ; get value
      defined?                      ; still valid value?
      (-> (do-something-with _)))   ; use value

    ; currying
    (define add2 
      (curry + 2))
    (define list-with-end 
      (rcurry list 23))
    (add2 3)                        ; 5
    (list-with-end 3 4 5)           ; (3 4 5 23)

    ; reverse currying
    (define rcmp (rev-curry cmp))
    (rcmp :a :b)                    ; 1
    (cmp :a :b)                     ; -1

    ; test for a code reference
    (lambda? value)

    ; cascading application
    (cascade 
      (get-value)                   ; 24    23
      (-> (if (even? _) _ #f))      ; 24    #f
      length                        ; 2 
      list)                         ; (2)

@DESCRIPTION

This library contains everything related to !TAGGED<functions> and runtime application.

=head1 PROVIDED FUNCTIONS

=head2 apply

!TAG<application>

    (apply <applicant> <arg1> ... <rest-arg-list>)

Using C<apply> you can do applications at runtime and dynamically build the argument
list. The last argument always has to be a list. This means the following are synonymous:

    (+ 1 2 3)
    (apply + 1 2 3 `())
    (apply + 1 2 `(3))
    (apply + 1 `(2 3))
    (apply + `(1 2 3))
    (apply apply `(,+ 1 `(2 3)))

You can use functions as well as objects as the applicant, like usual. And like always,
the call will be made in scalar context. See L</"apply/list"> if you need to call
something in list context.

=head2 apply/list

!TAG<application>
!TAG<context>

    (apply/list <applicant> <arg1> ... <rest-arg-list>)

This function does the same as L</apply> but the call will be made in list context, and
all returned values will be wrapped in a new list that will be returned. An example:

    (apply/list + 1 2 `(3))     ; returns (6)

=head2 while

!TAG<iteration>

    (while <iterator> <tester> <usage>)

You might wonder why C<while> is found in the functions library. This is because the while
in L<Template::SX> only takes function and applicant arguments. The arguments are, in order:

=over

=item *

A function that is called without arguments to fetch the next value.

=item *

A function that is called with the fetched value to test if it is valid. If it isn't, the
iteration ends and the last valid value will be returned.

=item *

A function or an object that will be called with each valid value as argument.

=back

So, a typical iteration over a resultset would look something like this:

    (while (<- (rs :next))
           defined?
           (-> (format-row _)))

=head2 curry

    (curry <applicant> <arg> ...)

This function will curry its first argument with all other passed in arguments. In more length,
this means that this function will return a new function. This new function will call the
C<applicant> with its arguments I<after> the arguments that were passed in during currying. An
exsample:

    (define add2 (curry + 2))
    (add2 3 4)                          ; 9

Since C<curry> takes an applicant and not just a function, you can also curry objects:

    (define call-foo (curry obj :foo))
    (call-foo 23)                       ; calls $obj->foo(23)

=head2 rcurry

    (rcurry <applicant> <arg> ...)

This function does the same as L</curry>, but it will add its arguments at the end of the real
function's argument list.

=head2 rev-curry

!TAG<order determination>

    (rev-curry <function>)

This will take a function and return another function. When the returned function is called,
the originally passed function will be called with the argument list in reverse. This is
especially useful for sorting values. For example, you could order entries descending with 
L<Template::SX::Library::Data::Strings/cmp> by saying:

    (sort ls (lambda (a b) (cmp b a)))

or by using this function:

    (sort ls (rev-curry cmp))

=head2 lambda?

    (lambda? <value> ...)

This predicate function tests whether all its arguments are code references. It requires at
least one argument.

=head2 cascade

    (cascade <value> <handler> ...)

The C<cascade> function will take the C<value> and call the first C<handler> with it as an argument.
It will then call the second handler with the return value of the first, and so on. It will do this
as long as the handlers return a defined value, or there are handlers left. As soon as an undefined
value is returned, the cascade ends and returns an undefined value as well.

So this:

    (cascade 23 foo bar baz)

is an easier way of saying:

    (let [(value 23)]
      (if (defined? value)
        (let [(foo_ret (foo value))]
          (if (defined? foo_ret)
            (let [(bar_ret (bar foo_ret))]
              (if (defined? bar_ret)
                (baz bar_ret)
                #f))
            #f))
        #f))

And the former is a lot more convenient to write.

=end fusion






=head1 NAME

Template::SX::Library::Data::Functions - This library contains all functionality regarded to functions and application.

=head1 SYNOPSIS

    ; applying with variable arguments
    (apply + 1 2 `(3 4))

    ; applying in list context
    (apply/list something 1 2 `(3 4))

    ; iterative calling
    (while 
      (<- (resultset :next))        ; get value
      defined?                      ; still valid value?
      (-> (do-something-with _)))   ; use value

    ; currying
    (define add2 
      (curry + 2))
    (define list-with-end 
      (rcurry list 23))
    (add2 3)                        ; 5
    (list-with-end 3 4 5)           ; (3 4 5 23)

    ; reverse currying
    (define rcmp (rev-curry cmp))
    (rcmp :a :b)                    ; 1
    (cmp :a :b)                     ; -1

    ; test for a code reference
    (lambda? value)

    ; cascading application
    (cascade 
      (get-value)                   ; 24    23
      (-> (if (even? _) _ #f))      ; 24    #f
      length                        ; 2 
      list)                         ; (2)

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Data::Functions

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

This library contains everything related to functions and runtime application.

=head1 PROVIDED FUNCTIONS

=head2 apply

    (apply <applicant> <arg1> ... <rest-arg-list>)

Using C<apply> you can do applications at runtime and dynamically build the argument
list. The last argument always has to be a list. This means the following are synonymous:

    (+ 1 2 3)
    (apply + 1 2 3 `())
    (apply + 1 2 `(3))
    (apply + 1 `(2 3))
    (apply + `(1 2 3))
    (apply apply `(,+ 1 `(2 3)))

You can use functions as well as objects as the applicant, like usual. And like always,
the call will be made in scalar context. See L</"apply/list"> if you need to call
something in list context.

=head2 apply/list

    (apply/list <applicant> <arg1> ... <rest-arg-list>)

This function does the same as L</apply> but the call will be made in list context, and
all returned values will be wrapped in a new list that will be returned. An example:

    (apply/list + 1 2 `(3))     ; returns (6)

=head2 while

    (while <iterator> <tester> <usage>)

You might wonder why C<while> is found in the functions library. This is because the while
in L<Template::SX> only takes function and applicant arguments. The arguments are, in order:

=over

=item *

A function that is called without arguments to fetch the next value.

=item *

A function that is called with the fetched value to test if it is valid. If it isn't, the
iteration ends and the last valid value will be returned.

=item *

A function or an object that will be called with each valid value as argument.

=back

So, a typical iteration over a resultset would look something like this:

    (while (<- (rs :next))
           defined?
           (-> (format-row _)))

=head2 curry

    (curry <applicant> <arg> ...)

This function will curry its first argument with all other passed in arguments. In more length,
this means that this function will return a new function. This new function will call the
C<applicant> with its arguments I<after> the arguments that were passed in during currying. An
exsample:

    (define add2 (curry + 2))
    (add2 3 4)                          ; 9

Since C<curry> takes an applicant and not just a function, you can also curry objects:

    (define call-foo (curry obj :foo))
    (call-foo 23)                       ; calls $obj->foo(23)

=head2 rcurry

    (rcurry <applicant> <arg> ...)

This function does the same as L</curry>, but it will add its arguments at the end of the real
function's argument list.

=head2 rev-curry

    (rev-curry <function>)

This will take a function and return another function. When the returned function is called,
the originally passed function will be called with the argument list in reverse. This is
especially useful for sorting values. For example, you could order entries descending with 
L<Template::SX::Library::Data::Strings/cmp> by saying:

    (sort ls (lambda (a b) (cmp b a)))

or by using this function:

    (sort ls (rev-curry cmp))

=head2 lambda?

    (lambda? <value> ...)

This predicate function tests whether all its arguments are code references. It requires at
least one argument.

=head2 cascade

    (cascade <value> <handler> ...)

The C<cascade> function will take the C<value> and call the first C<handler> with it as an argument.
It will then call the second handler with the return value of the first, and so on. It will do this
as long as the handlers return a defined value, or there are handlers left. As soon as an undefined
value is returned, the cascade ends and returns an undefined value as well.

So this:

    (cascade 23 foo bar baz)

is an easier way of saying:

    (let [(value 23)]
      (if (defined? value)
        (let [(foo_ret (foo value))]
          (if (defined? foo_ret)
            (let [(bar_ret (bar foo_ret))]
              (if (defined? bar_ret)
                (baz bar_ret)
                #f))
            #f))
        #f))

And the former is a lot more convenient to write.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Template::SX::Library::Data::Functions> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Library::Data>

=item * L<Template::SX::Library::ScopeHandling>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut