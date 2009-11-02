use MooseX::Declare;

class Template::SX::Library::Data::Regex extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;
    use utf8;

    use Template::SX::Util          qw( :all );
    use Template::SX::Constants     qw( :all );
    use Template::SX::Types         qw( :all );
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
