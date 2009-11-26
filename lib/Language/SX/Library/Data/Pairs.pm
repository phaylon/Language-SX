use MooseX::Declare;

class Language::SX::Library::Data::Pairs extends Language::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Name;
    use Language::SX::Types     qw( :all );
    use Language::SX::Constants qw( :all );
    use Language::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    my $ListToPairs = sub {
        my @ls = @{ $_[0] };

        E_PROTOTYPE->throw(
            class       => E_TYPE,
            attributes  => { message => 'unable to convert odd-sized list to list of pairs' },
        ) if scalar(@ls) % 2;

        my @pairs;
        while (my $key = shift @ls) {
            push @pairs, [$key, shift @ls];
        }

        return \@pairs;
    };

    my $HashToPairs = sub {
        my $hash = shift;

        return [ map { [$_, $hash->{ $_ }] } keys %$hash ];
    };

    CLASS->add_functions(
        'list->pairs'       => CLASS->wrap_function('list->pairs',      { min => 1, max => 1, types => [qw( list )] }, $ListToPairs),
        'hash->pairs'       => CLASS->wrap_function('hash->pairs',      { min => 1, max => 1, types => [qw( hash )] }, $HashToPairs),
        'compound->pairs'   => CLASS->wrap_function('compound->pairs',  { min => 1, max => 1, types => [qw( compound )] }, sub {
            my $comp = shift;
            
            return(
              ( (ref $comp eq 'HASH')
                ? $HashToPairs
                : $ListToPairs 
              )->($comp)
            );
        }),
    );

    my $IsPair = sub {

        for my $item (@_) {

            return undef unless ref $item eq 'ARRAY';
            return undef unless @$item == 2;
        }

        return 1;
    };

    my $IsPairList = sub {

        for my $list (@_) {

            return undef unless ref $list eq 'ARRAY';
            return undef unless $IsPair->(@$list);
        }

        return 1;
    };

    CLASS->add_functions(
        'pair?'  => CLASS->wrap_function('pair?',  { min => 1 }, $IsPair),
        'pairs?' => CLASS->wrap_function('pairs?', { min => 1 }, $IsPairList),
    );

    CLASS->add_functions(
        'pairs->list' => CLASS->wrap_function('pairs->list', { min => 1, max => 1 }, sub {
            my $pl = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'argument to pairs->list has to be a pair list' },
            ) unless $pl->$IsPairList;

            return [ map { (@$_) } @$pl ];
        }),
        'pairs->hash' => CLASS->wrap_function('pairs->hash', { min => 1, max => 1 }, sub {
            my $pl = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'argument to pairs->hash has to be a pair list' },
            ) unless $pl->$IsPairList;

            return +{ map { (@$_) } @$pl };
        }),
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Library::Data::Lists
@see_also Language::SX::Library::Data::Hashes
@license  Language::SX

@class Language::SX::Library::Data::Pairs
All functionality for working with pairs

@SYNOPSIS

    ; creating pair lists
    (list->pairs '(1 2 3 4))        ; ((1 2) (3 4))
    (hash->pairs { x: 2 y: 3 })     ; ((x: 2) (y: 3))
    (compound->pairs '(1 2 3 4))    ; ((1 2) (3 4))
    (compound->pairs { x: 2 y: 3 }) ; ((x: 2) (y: 3))

    ; predicates
    (pair? '(2 3))                  ; #t
    (pair? '(3))                    ; #f
    (pairs? '((2 3) (4 5)))         ; #t
    (pairs? '((2 3) (4)))           ; #f

    ; transforming pairs
    (pairs->list '((1 2) (3 4)))    ; (1 2 3 4)
    (pairs->hash '((x: 2) (y: 3)))  ; { x: 2 y: 3 }

@DESCRIPTION
Sometimes you want to process data pair-wise, but not as a key/value store. Maybe because 
you want to allow duplicate keys, maybe you want to allow non-string key values, or maybe
you simply care about the order. This library contains all built-in functionality concerned
with pairs and pair-wise data.

A pair is defined as an array reference containing exactly two values. 

=head1 PROVIDED FUNCTIONS

=head2 list->pairs

    (list->pairs <list>)

This function takes a even-sized C<list> as an argument and will return a new list
containing pairs made out of the original C<list>'s values. Here is a simple
example:

    (list->pairs '(1 2 3 4 5 6)) 
        ; returns ((1 2) (3 4) (5 6))

=head2 hash->pairs

    (hash->pairs <hash>)

Does the same as L</"list-E<gt>pairs"> but takes a hash instead of a list:

    (hash->pairs { x: 2 y: 3 z: 4 })
        ; returns ((x: 2) (y: 3) (z: 4))

=head2 compound->pairs

    (compound->pairs <list-or-hash>)

If the argument is a hash, it will be passed to L</"hash-E<gt>pairs">. If it is a list
it will be passed to L</"list-E<gt>pairs">.

=head2 pair?

    (pair? <item> ...)

This predicate function will return true if all arguments are pairs.

!TAG<type predicate>

=head2 pairs?

    (pairs? <item> ...)

This predicate function will return true if all arguments are lists of pairs.

!TAG<type predicate>

=head2 pairs->list

    (pairs->list <list-of-pairs>)

Transforms a list of pairs into a flat list:

    (pairs->list '((1 2) (3 4) (5 6)))
        ; returns (1 2 3 4 5 6)

=head2 pairs->hash

    (pairs->hash <list-of-pairs>)

Same as L</"pairs-E<gt>list"> but transforms the pairs into a hash.

=end fusion






=head1 NAME

Language::SX::Library::Data::Pairs - All functionality for working with pairs

=head1 SYNOPSIS

    ; creating pair lists
    (list->pairs '(1 2 3 4))        ; ((1 2) (3 4))
    (hash->pairs { x: 2 y: 3 })     ; ((x: 2) (y: 3))
    (compound->pairs '(1 2 3 4))    ; ((1 2) (3 4))
    (compound->pairs { x: 2 y: 3 }) ; ((x: 2) (y: 3))

    ; predicates
    (pair? '(2 3))                  ; #t
    (pair? '(3))                    ; #f
    (pairs? '((2 3) (4 5)))         ; #t
    (pairs? '((2 3) (4)))           ; #f

    ; transforming pairs
    (pairs->list '((1 2) (3 4)))    ; (1 2 3 4)
    (pairs->hash '((x: 2) (y: 3)))  ; { x: 2 y: 3 }

=head1 INHERITANCE

=over 2

=item *

Language::SX::Library::Data::Pairs

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

Sometimes you want to process data pair-wise, but not as a key/value store. Maybe because 
you want to allow duplicate keys, maybe you want to allow non-string key values, or maybe
you simply care about the order. This library contains all built-in functionality concerned
with pairs and pair-wise data.

A pair is defined as an array reference containing exactly two values. 

=head1 PROVIDED FUNCTIONS

=head2 list->pairs

    (list->pairs <list>)

This function takes a even-sized C<list> as an argument and will return a new list
containing pairs made out of the original C<list>'s values. Here is a simple
example:

    (list->pairs '(1 2 3 4 5 6)) 
        ; returns ((1 2) (3 4) (5 6))

=head2 hash->pairs

    (hash->pairs <hash>)

Does the same as L</"list-E<gt>pairs"> but takes a hash instead of a list:

    (hash->pairs { x: 2 y: 3 z: 4 })
        ; returns ((x: 2) (y: 3) (z: 4))

=head2 compound->pairs

    (compound->pairs <list-or-hash>)

If the argument is a hash, it will be passed to L</"hash-E<gt>pairs">. If it is a list
it will be passed to L</"list-E<gt>pairs">.

=head2 pair?

    (pair? <item> ...)

This predicate function will return true if all arguments are pairs.

=head2 pairs?

    (pairs? <item> ...)

This predicate function will return true if all arguments are lists of pairs.

=head2 pairs->list

    (pairs->list <list-of-pairs>)

Transforms a list of pairs into a flat list:

    (pairs->list '((1 2) (3 4) (5 6)))
        ; returns (1 2 3 4 5 6)

=head2 pairs->hash

    (pairs->hash <list-of-pairs>)

Same as L</"pairs-E<gt>list"> but transforms the pairs into a hash.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Language::SX::Library::Data::Pairs> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Library::Data::Lists>

=item * L<Language::SX::Library::Data::Hashes>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut