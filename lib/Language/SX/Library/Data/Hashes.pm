use MooseX::Declare;

class Language::SX::Library::Data::Hashes extends Language::SX::Library {
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

    CLASS->add_functions(hash => sub {

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => 'hash constructor expects even number of arguments' },
        ) if @_ % 2;

        return +{ @_ };
    });

    CLASS->add_functions('hash?', CLASS->wrap_function('hash?', { min => 1 }, sub {
        return scalar( grep { ref($_) ne 'HASH' } @_ ) ? undef : 1;
    }));

    CLASS->add_functions('hash-ref', CLASS->wrap_function('hash-ref', { min => 2, max => 2, types => [qw( hash )] }, sub {
        return $_[0]->{ $_[1] };
    }));

    CLASS->add_setter('hash-ref', CLASS->wrap_function('hash-ref', { min => 2, max => 2, types => [qw( hash )] }, sub {
        my ($hash, $key) = @_;
        return sub { $hash->{ $key } = shift };
    }));

    CLASS->add_functions('hash-splice', CLASS->wrap_function('hash-splice', { min => 2, max => 2, types => [qw( hash list )] }, sub {
        my ($hash, $keys) = @_;

        return +{ map {
            my ($idx, $key) = ($_, $keys->[ $_ ]);

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => sprintf 'entry %d in hash-splice key list is undefined', $idx + 1 },
            ) unless defined $key;

            ($key, $hash->{ $key }),
        } 0 .. $#$keys };
    }));

    CLASS->add_setter('hash-splice', CLASS->wrap_function('hash-splice', { min => 2, max => 2, types => [qw( hash list )] }, sub {
        my ($hash, $keys) = @_;

        for my $idx (0 .. $#$keys) {

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => sprintf 'entry %d in hash-splice setter key list is undefined', $idx + 1 },
            ) unless defined $keys->[ $idx ];
        }

        return sub {
            my $new = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'new value for hash-splice has to be a hash' },
            ) unless ref $new eq 'HASH';

            my %spliced = map { ($_ => delete($hash->{ $_ })) } @$keys;

            $hash->{ $_ } = $new->{ $_ }
                for keys %$new;
        
            return \%spliced;
        };
    }));

    CLASS->add_functions(
        'merge' => CLASS->wrap_function('merge', { all_type => 'compound' }, sub {
            return +{ map {
                (ref($_) eq 'HASH') 
                ? (%$_) 
                : (do { 
                    no warnings 'misc'; 
                    %{ +{ @$_} }
                  }
                ) 
            } @_ };
        }),
        'hash-map' => CLASS->wrap_function('hash-map', { min => 2, max => 2, types => [qw( hash applicant )] }, sub {
            my ($hash, $apply) = @_;
            return +{ map {
                ($_, apply_scalar(apply => $apply, arguments => [$_, $hash->{ $_ }]))
            } keys %$hash };
        }),
        'hash-grep' => CLASS->wrap_function('hash-grep', { min => 2, max => 2, types => [qw( hash applicant )] }, sub {
            my ($hash, $apply) = @_;
            return +{ map { ($_, $hash->{ $_ }) } grep {
                apply_scalar apply => $apply, arguments => [$_, $hash->{ $_ }];
            } keys %$hash };
        }),
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Library::Data::Pairs
@license  Language::SX

@class Language::SX::Library::Data::Hashes
All functionality related to working with hashes

@SYNOPSIS

    ; creating a new hash
    (hash x: 2 y: 3)

    ; hash predicate
    (hash? foo)

    ; accessing a single hash element 'bar' in foo
    (hash-ref foo :bar)

    ; changing a single hash element 'bar' in foo
    (set! (hash-ref foo :bar) 23)

    ; getting a splice of a hash
    (hash-splice foo '(x y z))

    ; replacing a splice of a hash
    (set! (hash-splice foo '(x y z)) { a: 3 b: 4 })

    ; merging hashes and lists into a hash
    (merge { x: 2 } '(y: 5))
        ; => { x: 2 y: 5 }

    ; mapping hash values
    (hash-map { x: 3 y: 4}
              (lambda (k v) "${k} is ${v}"))
        ; => { x: "x is 3" y: "y is 4" }

    ; filtering hashes
    (hash-grep
      { 2 3  5 7  9 9  3 2  1 5 }
      (lambda (k v) (even? (+ k v))))
        ; => { 5 7  9 9  1 5 }

@DESCRIPTION
This library contains all functionality concerned with dealing with hashes.

!TAG<hashes>

=head1 PROVIDED FUNCTIONS

=head2 hash

    (hash ...)

This function accepts an even-sized number of arguments and returns a new hash
using these arguments as keys and values.

=head2 hash?

    (hash? <item> ...)

Hash predicate function that will return true if all of its arguments are hash
references.

!TAG<type predicate>

=head2 hash-ref

    (hash-ref <hash> <key>)

Accesses a single value stored under C<key> in the C<hash>.

=head3 hash-ref Setter

    (set! (hash-ref <hash> <key>) <value>)

Sets the new C<value> as C<key> in the C<hash>.

!TAG<setter>

=head2 hash-splice

    (hash-splice <hash> <key-list>)

This function returns a new hash that will only contain the slots of the C<hash> argument
whose key was passed in the C<key-list>:

    (hash-splice { x: 2 y: 3 z: 4 } '(x z))
        ; => { x: 2 z: 4 }

=head3 hash-splice Setter

    (set! (hash-splice <hash> <key-list>) <new-hash>)

This !TAGGED<setter> has the same interface as the same-named function above. But instead of returning
the accessed values it will replace them with the key/value pairs in C<new-hash>.

=head2 merge

    (merge <compound> ...)

Takes any number of hash or list arguments and returns a new hash reference containing all the
values of the passed in C<compound>s:

    (merge '(1 2 3 4) { x: 3 } '(3 9))
        ; => { 1 2  x: 3 3 9 }

=head2 hash-map

    (hash-map <hash> <applicant>)

This function will call the C<applicant> with two values for each slot in the C<hash>. The first
argument will be the key and the second the value of the slot. The C<applicant> itself can be
either a code reference or an object.

!TAG<sequential mapping>

=head2 hash-grep

    (hash-grep <hash> <applicant>)

Just like with L</hash-map>, this function's C<applicant> will receive the key and the value as
arguments. It will return a new hash containing all the slots and their values for which the
C<applicant> returned true.

!TAG<filtering>

=end fusion






=head1 NAME

Language::SX::Library::Data::Hashes - All functionality related to working with hashes

=head1 SYNOPSIS

    ; creating a new hash
    (hash x: 2 y: 3)

    ; hash predicate
    (hash? foo)

    ; accessing a single hash element 'bar' in foo
    (hash-ref foo :bar)

    ; changing a single hash element 'bar' in foo
    (set! (hash-ref foo :bar) 23)

    ; getting a splice of a hash
    (hash-splice foo '(x y z))

    ; replacing a splice of a hash
    (set! (hash-splice foo '(x y z)) { a: 3 b: 4 })

    ; merging hashes and lists into a hash
    (merge { x: 2 } '(y: 5))
        ; => { x: 2 y: 5 }

    ; mapping hash values
    (hash-map { x: 3 y: 4}
              (lambda (k v) "${k} is ${v}"))
        ; => { x: "x is 3" y: "y is 4" }

    ; filtering hashes
    (hash-grep
      { 2 3  5 7  9 9  3 2  1 5 }
      (lambda (k v) (even? (+ k v))))
        ; => { 5 7  9 9  1 5 }

=head1 INHERITANCE

=over 2

=item *

Language::SX::Library::Data::Hashes

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

This library contains all functionality concerned with dealing with hashes.

=head1 PROVIDED FUNCTIONS

=head2 hash

    (hash ...)

This function accepts an even-sized number of arguments and returns a new hash
using these arguments as keys and values.

=head2 hash?

    (hash? <item> ...)

Hash predicate function that will return true if all of its arguments are hash
references.

=head2 hash-ref

    (hash-ref <hash> <key>)

Accesses a single value stored under C<key> in the C<hash>.

=head3 hash-ref Setter

    (set! (hash-ref <hash> <key>) <value>)

Sets the new C<value> as C<key> in the C<hash>.

=head2 hash-splice

    (hash-splice <hash> <key-list>)

This function returns a new hash that will only contain the slots of the C<hash> argument
whose key was passed in the C<key-list>:

    (hash-splice { x: 2 y: 3 z: 4 } '(x z))
        ; => { x: 2 z: 4 }

=head3 hash-splice Setter

    (set! (hash-splice <hash> <key-list>) <new-hash>)

This setter has the same interface as the same-named function above. But instead of returning
the accessed values it will replace them with the key/value pairs in C<new-hash>.

=head2 merge

    (merge <compound> ...)

Takes any number of hash or list arguments and returns a new hash reference containing all the
values of the passed in C<compound>s:

    (merge '(1 2 3 4) { x: 3 } '(3 9))
        ; => { 1 2  x: 3 3 9 }

=head2 hash-map

    (hash-map <hash> <applicant>)

This function will call the C<applicant> with two values for each slot in the C<hash>. The first
argument will be the key and the second the value of the slot. The C<applicant> itself can be
either a code reference or an object.

=head2 hash-grep

    (hash-grep <hash> <applicant>)

Just like with L</hash-map>, this function's C<applicant> will receive the key and the value as
arguments. It will return a new hash containing all the slots and their values for which the
C<applicant> returned true.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Language::SX::Library::Data::Hashes> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Library::Data::Pairs>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut