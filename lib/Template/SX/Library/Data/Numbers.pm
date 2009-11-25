use MooseX::Declare;

class Template::SX::Library::Data::Numbers extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use List::AllUtils          qw( min max );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';

    CLASS->add_functions(
        '+' => sub { my $n = shift; $n += $_ for @_; $n || 0 },
        '-' => sub { my $n = shift; $n -= $_ for @_; $n || 0 },
        '*' => sub { my $n = shift; $n *= $_ for @_; $n || 0 },
        '/' => sub { my $n = shift; $n /= $_ for @_; $n || 0 },
    );

    CLASS->add_functions(
        'range' => CLASS->wrap_function('range', { min => 2, max => 2 }, sub { [ +$_[0] .. +$_[1] ] }),
        'up-to' => CLASS->wrap_function('up-to', { min => 1, max => 1 }, sub { [0 .. +$_[0]] }),
    );

    CLASS->add_functions(
        '<=>' => sub {

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => '<=> expects exactly two numeric arguments' },
            ) unless @_ == 2;

            return $_[0] <=> $_[1];
        },
    );

    my $CheckManipArgs = sub {
        my $op = shift;

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => "function '$op' expects a single argument" },
        ) unless @_ == 1;
    };

    my $CheckScanArgs = sub {
        my $op = shift;

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => "function '$op' expects one or more arguments" },
        ) unless @_ >= 1;
    };

    CLASS->add_functions(
        abs => CLASS->wrap_function('abs', { min => 1, max => 1 }, sub { abs shift }),
        neg => CLASS->wrap_function('neg', { min => 1, max => 1 }, sub { (abs shift) * -1 }),
        int => CLASS->wrap_function('int', { min => 1, max => 1 }, sub { int shift }),
    );

    CLASS->add_functions(
        '=='    => CLASS->_build_equality_operator('=='),
        '!='    => CLASS->_build_nonequality_operator('!='), 
        '++'    => sub { $CheckManipArgs->('++', @_); $_[0] + 1 },
        '--'    => sub { $CheckManipArgs->('--', @_); $_[0] - 1 },
        '<'     => CLASS->_build_sequence_operator('<'),
        '>'     => CLASS->_build_sequence_operator('>'),
        '<='    => CLASS->_build_sequence_operator('<='),
        '>='    => CLASS->_build_sequence_operator('>='),
        min     => sub { $CheckScanArgs->('min', @_); min @_ },
        max     => sub { $CheckScanArgs->('max', @_); max @_ },
        'even?' => sub { 
            $CheckScanArgs->('even?', @_);
            return scalar( grep { $_ % 2 } @_ ) ? undef : 1;
        },
        'odd?'  => sub { 
            $CheckScanArgs->('odd?', @_);
            return scalar( grep { not($_ % 2) } @_ ) ? undef : 1;
        },
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Library::Data::Numbers
All numerical and math functionality

@SYNOPSIS

    ; the usual suspects
    (+ 2 3 4)               ; => 9
    (- 20 10 4)             ; => 6
    (* 2 2 2)               ; => 8
    (/ 3600 60 60)          ; => 1

    ; number ranges
    (range 3 5)             ; => (3 4 5)

    ; range from 0 to something
    (up-to 3)               ; => (0 1 2 3)

    ; numeric equality
    (sort '(3 5 1) <=>)     ; => (1 3 5)

    ; comparing numbers
    (== 3 3 3)
    (!= 3 4 5)
    (< 2 3 4)
    (> 4 3 2)
    (<= 2 2 3 3 4 4)
    (>= 4 4 3 3 2 2)

    ; increment and decrement
    (++ 3)                  ; => 4
    (-- 4)                  ; => 3

    ; finding min and max values
    (max 3 4 1 9 4)         ; => 9
    (min 3 4 1 9 4)         ; => 1

    ; absolutes, negatives and integers
    (abs -23)               ; => 23
    (neg 23)                ; => -23
    (int 2.5)               ; => 2

    ; even or odd
    (even? 4)
    (odd? 7)

@DESCRIPTION
This library contains all built-in functionality required to handle numbers or perform
mathematical calculations.

!TAG<math>

=head1 PROVIDED FUNCTIONS

=head2 +

    (+ <number> ...)

Simple addition function. It will return the sum of all passed in arguments or C<0> if
no arguments were present.

=head2 -

    (- <value> <subtract-number> ...)

The subtraction function will take the first argument and subtract all other arguments from it.
This will return the C<value> if no subtraction arguments are present, or C<0> if no arguments
are passed at all.

=head2 *

    (* <number> ...)

This function will multiply all its arguments and return the result. It will return C<0> if no
arguments are present.

=head2 /

    (/ <value> <divde-by> ...)

This division function will take the first argument and divide it sequentially by the following
arguments. It will return the C<value> itself if no division arguments were present, or C<0> if
no arguments were passed at all.

=head2 abs

    (abs <number>)

Returns the absolute of the number.

=head2 neg

    (neg <number>)

This is the opposite of L</abs>.

=head2 int

    (int <number>)

Turns the number into an integer.

=head2 range

    (range <start> <end>)

This function will return a list containing all numbers from (and including) C<start> up to C<end>.

=head2 up-to

    (up-to <end>)

This is a shorter form of L</range> that implicitly starts at C<0>.

=head2 <=>

    (<=> <number> <number>)

This will return the order of the passed numbers the same way as Perl's C<E<lt>=E<gt>> does. Look at
L<Template::SX::Library::Data::Lists/sort> for the most common usage of this function.

!TAG<order determination>

=head2 ==

    (== <number> <number> ...)

This equality function takes two or more arguments and tests whether they are numerically identical.

!TAG<equality>

=head2 !=

    (!= <number> <number> ...)

This non-equality function takes two or more arguments and tests whether non of them are numerically
identical.

!TAG<equality>

=head2 ++

    (++ <number>)

Returns the C<number> plus one.

=head2 --

    (-- <number>)

Returns the C<number> minus one.

=head2 <

    (< <number> ...)

This function will test if each argument is nuerically lower than the one following it.

=head2 >

    (> <number> ...)

This function will test if each argument is numerically higher than the one following it.

=head2 <=

    (<= <number>)

This function will test if each argument is nuerically lower than or equal to the one 
following it.

=head2 >=

    (>= <number> ...)

This function will test if each argument is numerically higher than or equal to the one 
following it.

=head2 min

    (min <number> ...)

Returns the argument value that is numerically the lowest.

=head2 max

    (max <number> ...)

Returns the argument value that is numerically the highest.

=head2 even?

    (even? <number> ...)

Tests if all arguments are numerically even.

=head2 odd?

    (odd? <number> ...)

Tests if all arguments are numerically odd.

=end fusion






=head1 NAME

Template::SX::Library::Data::Numbers - All numerical and math functionality

=head1 SYNOPSIS

    ; the usual suspects
    (+ 2 3 4)               ; => 9
    (- 20 10 4)             ; => 6
    (* 2 2 2)               ; => 8
    (/ 3600 60 60)          ; => 1

    ; number ranges
    (range 3 5)             ; => (3 4 5)

    ; numeric equality
    (sort '(3 5 1) <=>)     ; => (1 3 5)

    ; comparing numbers
    (== 3 3 3)
    (!= 3 4 5)
    (< 2 3 4)
    (> 4 3 2)
    (<= 2 2 3 3 4 4)
    (>= 4 4 3 3 2 2)

    ; increment and decrement
    (++ 3)                  ; => 4
    (-- 4)                  ; => 3

    ; finding min and max values
    (max 3 4 1 9 4)         ; => 9
    (min 3 4 1 9 4)         ; => 1

    ; even or odd
    (even? 4)
    (odd? 7)

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Data::Numbers

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

This library contains all built-in functionality required to handle numbers or perform
mathematical calculations.

=head1 PROVIDED FUNCTIONS

=head2 +

    (+ <number> ...)

Simple addition function. It will return the sum of all passed in arguments or C<0> if
no arguments were present.

=head2 -

    (- <value> <subtract-number> ...)

The subtraction function will take the first argument and subtract all other arguments from it.
This will return the C<value> if no subtraction arguments are present, or C<0> if no arguments
are passed at all.

=head2 *

    (* <number> ...)

This function will multiply all its arguments and return the result. It will return C<0> if no
arguments are present.

=head2 /

    (/ <value> <divde-by> ...)

This division function will take the first argument and divide it sequentially by the following
arguments. It will return the C<value> itself if no division arguments were present, or C<0> if
no arguments were passed at all.

=head2 range

    (range <start> <end>)

This function will return a list containing all numbers from (and including) C<start> up to C<end>.

=head2 <=>

    (<=> <number> <number>)

This will return the order of the passed numbers the same way as Perl's C<E<lt>=E<gt>> does. Look at
L<Template::SX::Library::Data::Lists/sort> for the most common usage of this function.

=head2 ==

    (== <number> <number> ...)

This equality function takes two or more arguments and tests whether they are numerically identical.

=head2 !=

    (!= <number> <number> ...)

This non-equality function takes two or more arguments and tests whether non of them are numerically
identical.

=head2 ++

    (++ <number>)

Returns the C<number> plus one.

=head2 --

    (-- <number>)

Returns the C<number> minus one.

=head2 <

    (< <number> ...)

This function will test if each argument is nuerically lower than the one following it.

=head2 >

    (> <number> ...)

This function will test if each argument is numerically higher than the one following it.

=head2 <=

    (<= <number>)

This function will test if each argument is nuerically lower than or equal to the one 
following it.

=head2 >=

    (>= <number> ...)

This function will test if each argument is numerically higher than or equal to the one 
following it.

=head2 min

    (min <number> ...)

Returns the argument value that is numerically the lowest.

=head2 max

    (max <number> ...)

Returns the argument value that is numerically the highest.

=head2 even?

    (even? <number> ...)

Tests if all arguments are numerically even.

=head2 odd?

    (odd? <number> ...)

Tests if all arguments are numerically odd.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Template::SX::Library::Data::Numbers> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut
