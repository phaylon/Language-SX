use MooseX::Declare;

class Language::SX::Library::Data::Strings extends Language::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Language::SX::Types     qw( :all );
    use Language::SX::Constants qw( :all );
    use Language::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_functions(
        'string'  => sub { join '', @_ },
        'string?' => CLASS->wrap_function('string?', { min => 1 }, sub {
            return scalar( grep { ref or not defined } @_ ) ? undef : 1;
        }),
    );

    CLASS->add_functions(
        cmp => CLASS->wrap_function('cmp', { min => 2, max => 2 }, sub {
            return scalar( $_[0] cmp $_[1] );
        }),
    );

    CLASS->add_functions(
        split => CLASS->wrap_function('split', { min => 2, max => 2, types => [qw( regex )] }, sub {
            my ($rx, $str) = @_;
            return [ split($rx, "$str") ];
        }),
    );

    CLASS->add_functions(
        'eq?' => CLASS->_build_equality_operator(   eq => 'eq?'),
        'ne?' => CLASS->_build_nonequality_operator(ne => 'ne?'),
        'lt?' => CLASS->_build_sequence_operator(   lt => 'lt?'),
        'le?' => CLASS->_build_sequence_operator(   le => 'le?'),
        'gt?' => CLASS->_build_sequence_operator(   gt => 'gt?'),
        'ge?' => CLASS->_build_sequence_operator(   ge => 'ge?'),
    );

    CLASS->add_functions(
        'upper'         => CLASS->_build_unary_builtin_function('uc', 'upper'),
        'lower'         => CLASS->_build_unary_builtin_function('lc', 'lower'),
        'upper-first'   => CLASS->_build_unary_builtin_function('ucfirst', 'upper-first'),
        'lower-first'   => CLASS->_build_unary_builtin_function('lcfirst', 'lower-first'),
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Library::Data::Strings
All functionality related to working with strings

@SYNOPSIS

    ; create a string
    (string "foo: " bar)

    ; string predicate
    (string? foo)

    ; determine alphabetical order
    (cmp string-a string-b)

    ; splitting a string into a list
    (split rx/\s+/ "foo bar baz")

    ; equality test
    (eq? :x :x :x)
    (ne? :a :b :c)

    ; order test
    (lt? :a :b :c)
    (le? :a :a :b :c)
    (gt? :c :b :a)
    (ge? :c :c :b :a)

    ; case transformations
    (upper "foo")           ; FOO
    (lower "FOO")           ; foo
    (upper-first "foo")     ; Foo
    (lower-first "FOO")     ; fOO

@DESCRIPTION
This library contains all functionality required for string handling and manipulation.

!TAG<strings>

=head1 PROVIDED FUNCTIONS

=head2 string

    (string ...)

Joins all arguments together without a separator. Returns an empty string when called
without arguments.

=head2 string?

    (string? <item> ...)

Tests if all arguments are strings (defined but not references).

!TAG<type predicate>

=head2 cmp

    (cmp <string-a> <string-b>)

Determines the order of its two arguments the same way Perl's operator of the same name
does. Look at L<Language::SX::Library::Data::Lists/sort> for the most common use of this
function.

!TAG<order determination>

=head2 split

    (split <regex> <string>)

Takes a regular expression and a string and breaks the string up by the separator defined
by the regular expression.

=head2 eq?

    (eq? <string> <string> ...)

Takes two or more arguments and tests if they are all alphabetically equal.

!TAG<equality>

=head2 ne?

    (ne? <string> <string> ...)

Takes two or more arguments and tests if none of them are alphabetically equal.

!TAG<equality>

=head2 lt?

    (lt? <string> ...)

Tests if every argument is alphabetically lower than the one that follows it.

=head2 le?

    (le? <string> ...)

Tests if every argument is alphabetically lower than or equal to the one that 
follows it.

=head2 gt?

    (gt? <string> ...)

Tests if every argument is alphabetically greater than the one that follows it.

=head2 ge?

    (ge? <string> ...)

Tests if every argument is alphabetically greater than or equal to the one that 
follows it.

=head2 upper

    (upper <string>)

Returns the !TAGGED<upper-case> version of the C<string>.

=head2 lower

    (lower <string>)

Returns the !TAGGED<lower-case> version of the C<string>.

=head2 upper-first

    (upper-first <string>)

Returns the C<string> with the first character in !TAGGED<upper-case>.

=head2 lower-first

    (lower-first <string>)

Returns the C<string> with the first character in !TAGGED<lower-case>.

=end fusion






=head1 NAME

Language::SX::Library::Data::Strings - All functionality related to working with strings

=head1 SYNOPSIS

    ; create a string
    (string "foo: " bar)

    ; string predicate
    (string? foo)

    ; determine alphabetical order
    (cmp string-a string-b)

    ; splitting a string into a list
    (split rx/\s+/ "foo bar baz")

    ; equality test
    (eq? :x :x :x)
    (ne? :a :b :c)

    ; order test
    (lt? :a :b :c)
    (le? :a :a :b :c)
    (gt? :c :b :a)
    (ge? :c :c :b :a)

    ; case transformations
    (upper "foo")           ; FOO
    (lower "FOO")           ; foo
    (upper-first "foo")     ; Foo
    (lower-first "FOO")     ; fOO

=head1 INHERITANCE

=over 2

=item *

Language::SX::Library::Data::Strings

=over 2

=item *

L<Language::SX::Library>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This library contains all functionality required for string handling and manipulation.

=head1 PROVIDED FUNCTIONS

=head2 string

    (string ...)

Joins all arguments together without a separator. Returns an empty string when called
without arguments.

=head2 string?

    (string? <item> ...)

Tests if all arguments are strings (defined but not references).

=head2 cmp

    (cmp <string-a> <string-b>)

Determines the order of its two arguments the same way Perl's operator of the same name
does. Look at L<Language::SX::Library::Data::Lists/sort> for the most common use of this
function.

=head2 split

    (split <regex> <string>)

Takes a regular expression and a string and breaks the string up by the separator defined
by the regular expression.

=head2 eq?

    (eq? <string> <string> ...)

Takes two or more arguments and tests if they are all alphabetically equal.

=head2 ne?

    (ne? <string> <string> ...)

Takes two or more arguments and tests if none of them are alphabetically equal.

=head2 lt?

    (lt? <string> ...)

Tests if every argument is alphabetically lower than the one that follows it.

=head2 le?

    (le? <string> ...)

Tests if every argument is alphabetically lower than or equal to the one that 
follows it.

=head2 gt?

    (gt? <string> ...)

Tests if every argument is alphabetically greater than the one that follows it.

=head2 ge?

    (ge? <string> ...)

Tests if every argument is alphabetically greater than or equal to the one that 
follows it.

=head2 upper

    (upper <string>)

Returns the upper-case version of the C<string>.

=head2 lower

    (lower <string>)

Returns the lower-case version of the C<string>.

=head2 upper-first

    (upper-first <string>)

Returns the C<string> with the first character in upper-case.

=head2 lower-first

    (lower-first <string>)

Returns the C<string> with the first character in lower-case.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Language::SX::Library::Data::Strings> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut