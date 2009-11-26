use MooseX::Declare;

class Language::SX::Library::Data::Regex extends Language::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;
    use utf8;

    use Language::SX::Util          qw( :all );
    use Language::SX::Constants     qw( :all );
    use Language::SX::Types         qw( :all );
    use Regexp::Compare             qw( is_less_or_equal );

    Class::MOP::load_class($_)
        for E_SYNTAX, E_RESERVED, E_PROTOTYPE;

    class_has '+function_map';
    class_has '+syntax_map';

    my $WrapRegex = sub {
        my $str = shift;
        return qr/$str/;
    };

    my $ItemToRegex;
    $ItemToRegex = sub {
        my $item = shift;
        my $ref  = ref $item;

        if ($ref eq 'Regexp') {
            return $item;
        }
        elsif (not($ref) and defined($item)) {
            return $WrapRegex->(quotemeta $item);
        }
        elsif ($ref eq 'ARRAY') {
            return $WrapRegex->(
                join('|', 
                    map { "(?:$_)" } 
                    map { $ItemToRegex->($_) }
                    @$item
                ),
            );
        }
        elsif ($ref eq 'HASH') {
            return $WrapRegex->(
                join('|', 
                    map {
                        sprintf(
                            '(?<%s>%s)',
                            $_,
                            $ItemToRegex->($item->{ $_ }),
                        );
                    }
                    sort {
                        length($item->{ $b }) <=> length($item->{ $a })
                    }
                    grep {
                        ( /\A [_a-z] [_a-z0-9]* \Z/ix )
                        ? 1
                        : do {
                            # TODO better warning facilities that report correct location
                            warn "skipping invalid match name '$_'\n";
                            undef;
                        };
                    }
                    keys %$item
                ),
            );
        }
        else {
            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => "unable to transform item $item into regular expression" },
            );
        }
    };

    CLASS->add_functions(
        'regex?' => CLASS->wrap_function('regex?', { min => 1 }, sub {
            return scalar( grep { ref ne 'Regexp' } @_ ) ? undef : 1;
        }),
        'regex' => sub {

            my @parts;
            for my $part (@_) {
                push @parts, $ItemToRegex->($part);
            }

            return $WrapRegex->(join('', @parts));
        },
    );

    CLASS->add_functions(
        'string->regex' => CLASS->wrap_function('string->regex', { min => 1, max => 1, types => [qw( string )] }, $WrapRegex),
    );

    CLASS->add_functions(
        'match' => CLASS->wrap_function('match', { min => 2, max => 2, types => [qw( string regex )] }, sub {
            my ($str, $rx) = @_;

            return(
                ( $str =~ $rx )
                ? +{ %+ }
                : undef
            );
        }),
        'match-all' => CLASS->wrap_function('match-all', { min => 2, max => 2, types => [qw( string regex )] }, sub {
            my ($str, $rx) = @_;

            my @matches;

            while ($str =~ /$rx/g) {
                push @matches, +{ %+ };
            }

            return \@matches;
        }),
        'replace' => CLASS->wrap_function('replace', { min => 3, max => 3, types => [qw( string regex lambda )] }, sub {
            my ($str, $rx, $cb) = @_;

            $str =~ s/$rx/
                apply_scalar apply => $cb, arguments => [{ %+ }];
            /eg;

            return $str;
        }),
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Library::Data::Regex
All regular expression functionality

@SYNOPSIS

    ; create a new regular expression
    (regex 
      '(foo bar)        ; or
      { x: 3 y: 4 }     ; named or
      "[]"              ; auto-quoted
      rx/foo/)          ; regex interpolation

    ; regex predicate
    (regex? foo)

    ; when the regex is inside a string
    (string->regex "[abc]")

    ; matching a string
    (match "foo" (regex { str: "o" }))
        ; returns { str: "o" }

    ; matching all occurances in a string
    (match-all "foo" (regex { str: "o" }))
        ; returns ({ str: "o" } { str: "o" })

    ; replacing something in a string
    (replace 
      "foo" 
      (regex { str: "o" }) 
      (-> (upper (at _ :str))))
        ; returns "fOO"

@DESCRIPTION
This library contains all functionality necessary to create and use regular expressions.

!TAG<regular expressions>

Regular expressions in L<Language::SX> are in the following format:

    rx/.../i

There is currently no way to interpolate a regular expression besides using L</regex> to
construct one or use L</string-E<gt>regex> to make one out of a string.

=head1 PROVIDED FUNCTIONS

=head2 regex

    (regex ...)

This function turns all its arguments into a single regular expression. The following
value types are valid:

=over

=item * A regular expression

Regular expressions will be interpolated as they are.

=item * A string

Strings will be quoted so they match literally. If you want to use regex syntax inside
the string see L</string-E<gt>regex>.

=item * An array reference

An array reference is basically an C<or> junction between any type of value contained
in this list.

=item * A hash reference

Hashes are used as named C<or> junctions. The keys of the hash are used as capture names
while the values can be of any interpolatable type.

=back

=head2 regex?

!TAG<type predicate>

    (regex? <item> ...)

Tests if all arguments are regular expressions.

=head2 string->regex

    (string->regex <string>)

This function will take a string and return it as a regular expression. The string will
not be quoted. Use L</regex> to build regular expressions with literal string parts.

=head2 match

    (match <string> <regex>)

This will return a hash reference containing all named captures of the first possible match
of the C<regex> in the C<string>.

=head2 match-all

    (match-all <string> <regex>)

This is the same as L</match>, except that it will return a list containing all matches of
C<regex> in the C<string>.

=head2 replace

    (replace <string> <regex> <replacer-function>)

This will invoke the C<replacer-function> for every match of C<regex> in C<string> and replace
the matched part with the value returned.

=end fusion






=head1 NAME

Language::SX::Library::Data::Regex - All regular expression functionality

=head1 SYNOPSIS

    ; create a new regular expression
    (regex 
      '(foo bar)        ; or
      { x: 3 y: 4 }     ; named or
      "[]"              ; auto-quoted
      rx/foo/)          ; regex interpolation

    ; regex predicate
    (regex? foo)

    ; when the regex is inside a string
    (string->regex "[abc]")

    ; matching a string
    (match "foo" (regex { str: "o" }))
        ; returns { str: "o" }

    ; matching all occurances in a string
    (match-all "foo" (regex { str: "o" }))
        ; returns ({ str: "o" } { str: "o" })

    ; replacing something in a string
    (replace 
      "foo" 
      (regex { str: "o" }) 
      (-> (upper (at _ :str))))
        ; returns "fOO"

=head1 INHERITANCE

=over 2

=item *

Language::SX::Library::Data::Regex

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

This library contains all functionality necessary to create and use regular expressions.

Regular expressions in L<Language::SX> are in the following format:

    rx/.../i

There is currently no way to interpolate a regular expression besides using L</regex> to
construct one or use L</string-E<gt>regex> to make one out of a string.

=head1 PROVIDED FUNCTIONS

=head2 regex

    (regex ...)

This function turns all its arguments into a single regular expression. The following
value types are valid:

=over

=item * A regular expression

Regular expressions will be interpolated as they are.

=item * A string

Strings will be quoted so they match literally. If you want to use regex syntax inside
the string see L</string-E<gt>regex>.

=item * An array reference

An array reference is basically an C<or> junction between any type of value contained
in this list.

=item * A hash reference

Hashes are used as named C<or> junctions. The keys of the hash are used as capture names
while the values can be of any interpolatable type.

=back

=head2 regex?

    (regex? <item> ...)

Tests if all arguments are regular expressions.

=head2 string->regex

    (string->regex <string>)

This function will take a string and return it as a regular expression. The string will
not be quoted. Use L</regex> to build regular expressions with literal string parts.

=head2 match

    (match <string> <regex>)

This will return a hash reference containing all named captures of the first possible match
of the C<regex> in the C<string>.

=head2 match-all

    (match-all <string> <regex>)

This is the same as L</match>, except that it will return a list containing all matches of
C<regex> in the C<string>.

=head2 replace

    (replace <string> <regex> <replacer-function>)

This will invoke the C<replacer-function> for every match of C<regex> in C<string> and replace
the matched part with the value returned.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Language::SX::Library::Data::Regex> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut