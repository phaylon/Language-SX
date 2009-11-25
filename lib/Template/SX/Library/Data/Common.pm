use MooseX::Declare;

class Template::SX::Library::Data::Common extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Data::Dump              qw( pp );
    use Scalar::Util            qw( blessed );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_setter(
        'values' => CLASS->wrap_function('values', { min => 1, max => 2, types => [qw( compound list )] }, sub {
            my ($target, $keys) = @_;

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'setting hash values requires a list of keys' },
            ) if not($keys) and ref $target eq 'HASH';

            if ($keys) {
    
                for my $idx (0 .. $#$keys) {

                    E_PROTOTYPE->throw(
                        class       => E_TYPE,
                        attributes  => { message => sprintf 'value setter key list item %d is undefined', $idx + 1 },
                    ) unless defined $keys->[ $idx ];
                }
            }

            return sub {
                my $new = shift;

                E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => 'values setter expects a list of new values' },
                ) unless ref $new eq 'ARRAY';

                E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => sprintf 'unable to save %d values under %d keys', scalar(@$new), scalar(@$keys) },
                ) if $keys and @$new != @$keys;

                my @old;

                if (ref $target eq 'HASH') {
                    @old = @{ $target }{ @$keys };
                    @{ $target }{ @$keys } = @$new;
                }
                else {
                    if ($keys) {
                        @old = @{ $target }[ @$keys ];
                        @{ $target }[ @$keys ] = @$new;
                    }
                    else {
                        @old = @$target;
                        @$target = @$new;
                    }
                }

                return \@old;
            };
        }),
    );

    CLASS->add_functions(
        'defined?' => sub {
            return undef unless @_;
            return undef if grep { not defined } @_;
            return 1;
        },
        'reverse' => CLASS->wrap_function('reverse', { min => 1, max => 1, types => [qw( any )] }, sub {
            my $item = shift;

            return(
                ( ref($item) eq 'HASH' )                  ? { reverse %$item }
              : ( ref($item) eq 'ARRAY' )                 ? [ reverse @$item ]
              : ( not(ref($item)) and defined($item) )    ? reverse("$item")
              : E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => sprintf(q(unable to reverse '%s'), $item) },
                )
            );
        }),
        'length' => CLASS->wrap_function('length', { min => 1, max => 1 }, sub {
            my $item = shift;

            return
                ( ref($item) eq 'ARRAY' )               ? scalar(@$item)
              : ( ref($item) eq 'HASH' )                ? scalar(keys %$item)
              : ( defined($item) and not ref $item )    ? length($item)
              : E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => sprintf(q(unable to calculate length from '%s'), $item) },
                );
        }),
        'empty?' => sub {

            for my $n (@_) {
                
                next if not( defined $n )
                     or (
                        ref($n)
                        ? ( ref($n) eq 'HASH'  ? not( keys %$n )
                          : ref($n) eq 'ARRAY' ? not( @$n )
                          : 0
                        )
                        : not( length $n )
                     );

                return undef;
            }

            return 1;
        },
        'keys' => sub {
            
            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'keys expects one hash or list argument' },
            ) unless @_ == 1;

            my $arg = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'argument to keys is not a hash or list' },
            ) unless ref $arg eq 'HASH' or ref $arg eq 'ARRAY';

            return +( ref $arg eq 'HASH' ) ? [keys %$arg] : [0 .. $#$arg];
        },
        values => sub {
            
            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'values expects a required data and an optional key list argument' },
            ) unless @_ == 1 or @_ == 2;

            my $arg  = shift; my $arg_ref  = ref $arg;
            my $keys = shift; my $keys_ref = ref $keys;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'key list argument to values must be a list' },
            ) if defined $keys and $keys_ref ne 'ARRAY';

            if ($keys) {

                for my $idx (0 .. $#$keys) {

                    E_PROTOTYPE->throw(
                        class       => E_TYPE,
                        attributes  => { message => sprintf 'values key list item %d is undefined', $idx + 1 },
                    ) unless defined $keys->[ $idx ];
                }
            }

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'data argument to values is not a hash or list' },
            ) unless $arg_ref eq 'HASH' or $arg_ref eq 'ARRAY';

            if ($arg_ref eq 'ARRAY') {
                return [ $keys ? @{ $arg }[ @$keys ] : @$arg ];
            }
            else {
                return [ $keys ? @{ $arg }{ @$keys } : values %$arg ];
            }
        },
    );

    method _build_deep_getter (ClassName $class: CodeRef :$on_last?) {

        return sub {
            my ($data, @path) = @_;

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'deep data structure access requires at least the data structure argument' },
            ) unless @_;

            for my $idx (0 .. $#path) {
                my $key = $path[ $idx ];

                E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => "data path item at position $idx (starting with 0) is undefined" },
                ) unless defined $key;

                if ($on_last and $idx == $#path) {
                    return $on_last->($data, $key);
                }

                if (ref $data eq 'ARRAY') {
                    return undef unless exists $data->[ $key ];
                    $data = $data->[ $key ];
                }
                elsif (ref $data eq 'HASH') {
                    return undef unless exists $data->{ $key };
                    $data = $data->{ $key };
                }
                elsif (blessed $data) {
                    return undef unless $data->can($key);
                    $data = apply_scalar apply => $data, arguments => [$key];
                }
                else {
                    return undef;
                }
            }

            return $data;
        };
    }

    CLASS->add_functions('exists?' => CLASS->_build_deep_getter(
        on_last => sub {
            ref($_[0]) eq 'HASH'    ? ( exists($_[0]->{ $_[1] }) ? 1 : undef )
          : ref($_[0]) eq 'ARRAY'   ? ( exists($_[0]->[ $_[1] ]) ? 1 : undef )
          : blessed($_[0])          ? ( $_[0]->can($_[1])        ? 1 : undef )
          : undef
        },
    ));

    CLASS->add_functions(at => CLASS->_build_deep_getter);
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Library::Data
@see_also Template::SX::Library::ScopeHandling
@license  Template::SX

@class Template::SX::Library::Data::Common
Common data functionality

@SYNOPSIS

    ; values
    (values { x: 2 y: 3 } `(x y))       => (2 3)
    (values `(3 4 5) `(1 2))            => (4 5)

    ; setting values
    (set! (values somehash `(key1 key2)) (list val1 val2))
    (set! (values somelist) somevaluelist)
    (set! (values somelist `(3 4)) (list val1 val2))

    ; definitions
    (if (defined? val)
      "defined"
      "not defined")

    ; reversing
    (reverse `(1 2 3))      => (3 2 1)
    (reverse { x: 2 y: 3})  => { 2 "x" 3 "y" }
    (reverse "123")         => "321"

    ; lengths
    (length `(1 2 3))       => 3
    (length { x: 2 y: 3 })  => 2
    (length "123")          => 3

    ; emptiness
    (empty? `())            => #t
    (empty? {})             => #t
    (empty? "")             => #t

    ; indexes
    (keys `(3 4 5))         => (0 1 2)
    (keys { x: 2 y: 3 })    => ("x" "y")

    ; existence
    (exists? data :key 3 :otherkey)

    ; accessing
    (at data :key 3 :otherkey)

@DESCRIPTION

This library contains common functionality for multiple and general types of data.

=head1 PROVIDED FUNCTIONS

=head2 values

    (values <hash> <key-list>)
    (values <list> <idx-list>)
    (values <list>)
    (values <hash>)

This function returns the values of a compound data structure, such as a hash or
array reference. It optionally takes a list of keys (or indexes in case of an array).

You should only use this without a list of keys if you don't care about the order.

=head3 values Setter

    (set! (values <hash> <keys>) <new-list>)
    (set! (values <list> <indexes>) <new-list>)
    (set! (values <list>) <new-list>)

This !TAGGED<setter> will replace values in a compound data structure with new ones. Hashes
have to receive a key list, otherwise we'd run into order issues.

The list of new values must also be of the same size as the replaced section. For
lists without an index list, this is the size of the list itself. For all others, the
number of elements in the new value list must be the same as the number of keys or
indexes. Some examples:

    (define myhash { x: 3 y: 4 z: 5 })
    (define mylist `(1 2 3 4))

    (set! (values myhash `(x z)) `(7 8))
    ; myhash is now { x: 7 y: 4 z: 8 }

    (set! (values mylist) `(3 4 5 6))
    ; mylist is now (3 4 5 6)

    (set (values mylist `(1 2)) `(7 8))
    ; mylist is now (3 7 8 6)

=head2 defined?

    (defined? ...)

This predicate function takes one or more arguments and assures that all of them are
defined. It will return an undefined value if no arguments are passed.

!TAG<type predicate>

=head2 reverse

    (reverse <hash>)
    (reverse <list>)
    (reverse <string>)

Sometimes you need to reverse some data. This function can take a single list, hash or
string and return its reversal. This works the same way as Perl does. A list as
argument leads to a new list with a reversed order of elements. The same happens with
a string but with characters instead of elements. Since hashes don't have orderings, a
reversal of a hash is a swap of the key/value pairs.

Some examples:

    (reverse "abc")         => "cba"
    (reverse `(1 2 3))      => (3 2 1)
    (reverse { x: 3 y: 4 }) => { 3 "x" 4 "y" }

=head2 length

    (length <string>)
    (length <list>)
    (length <hash>)

This function calculates the length of either a list, a hash or a string. With lists
the count of elements is returned, with a hash the number of key/value pairs, and with
a string the number of characters according to perl's C<length>.

=head2 empty?

    (empty? <value> ...)

This function will test if all of its arguments are empty. Will return a true value if
no arguments were specified. An item is empty if:

=over

=item * for hashes:

There are no keys.

=item * for lists:

The list has no elements.

=item * for strings:

The string has zero length. C<0> is not empty.

=item * for all other values:

If the value is undefined.

=back

=head2 keys

    (keys <hash>)
    (keys <list>)

This function takes a single compound argument and returns a list of keys (or indexes
if a list was passed):

    (keys `(3 4 5))         => (0 1 2)
    (keys { x: 3 y: 4 })    => ("x" "y") or ("y" "x")

As usual with Perl, hash key order is undefined.

=head2 exists?

    (exists? <data> <path-item> ...)

This is the function to test existance in all compound structures. It is rather easy.
Imagine the following data structure:

    (define data
        { users: 
            (list { name: "foo" }
                  { name: "bar" })
          admins:
            (list { name: "baz" }
                  { name: "qux" }) })

You could check if the second user has a name with the code:

    (exists? data :users 1 :name)

This is basically the same as Perl's

    exists $data->{users}[1]{name}

See L</at> for an explanation on the differences in Perl's and Template::SX's
behaviour. When the item to be checked is an object, one of two things might happen:

=over

=item * If the object is the last element in the path:

If the object is encountered at the end of the path, only a call to C<can> will be
performed to make sure a method of that name is available. This means that this code:

    (exists? obj :foo)

will test if the C<obj> has a method called C<foo>. It will return a boolean value. If
you want to get at the code reference, you will have to call C<can> yourself.

=item * If there are more path items to test:

When you have specified further path items beyond the object, the method will be called
and the path is continued on the methods return value. As an example:

    (exists? obj :foo :bar)

This would B<call> the C<foo> method on C<obj> without arguments, and test the existance
of a C<bar> key in the methods return value.

=back

=head2 at

    (at <data> <path-item> ...)

This returns the value in the data structure at the specific path. The format
is exactly the same as with L</exists?>.

Unlike C<exists?> when an object is encountered the methods are always called. Even if
its the final item in the path.

There are a couple of differences between how L<Template::SX> and Perl handle deep
structure access. This holds true for C<at> and L</exists?>. The differences are:

=over

=item * You don't need to worry about the type.

If you want to make sure a value is of a certain type, make the required checks
yourself. This has the advantage that together with C<apply> you can pass around
data access paths as first class values:

    (define (deep-join sep data . paths)
      (join sep
            (map paths
                 (-> (apply at data _)))))

    (define mydata
      { users:  (list { name: "foo" }
                      { name: "bar" })
        admins: (list { name: "baz" tags: (list "tag1" "tag2") }
                      { name: "qux" }) })

    ; generates "foo, bar, tag1"
    (deep-join ", " mydata
      `(users 0 name)
      `(users 1 name)
      `(admins 0 tags 0))

=item * It won't autovivify the tested structure.

If you want to change the datastructure, you will have to do it explicitely. Both
C<at> and L</exists?> will return an undefined value as soon as a path item was not
found as key.

=back

=end fusion






=head1 NAME

Template::SX::Library::Data::Common - Common data functionality

=head1 SYNOPSIS

    ; values
    (values { x: 2 y: 3 } `(x y))       => (2 3)
    (values `(3 4 5) `(1 2))            => (4 5)

    ; setting values
    (set! (values somehash `(key1 key2)) (list val1 val2))
    (set! (values somelist) somevaluelist)
    (set! (values somelist `(3 4)) (list val1 val2))

    ; definitions
    (if (defined? val)
      "defined"
      "not defined")

    ; reversing
    (reverse `(1 2 3))      => (3 2 1)
    (reverse { x: 2 y: 3})  => { 2 "x" 3 "y" }
    (reverse "123")         => "321"

    ; lengths
    (length `(1 2 3))       => 3
    (length { x: 2 y: 3 })  => 2
    (length "123")          => 3

    ; emptiness
    (empty? `())            => #t
    (empty? {})             => #t
    (empty? "")             => #t

    ; indexes
    (keys `(3 4 5))         => (0 1 2)
    (keys { x: 2 y: 3 })    => ("x" "y")

    ; existence
    (exists? data :key 3 :otherkey)

    ; accessing
    (at data :key 3 :otherkey)

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Data::Common

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

This library contains common functionality for multiple and general types of data.

=head1 PROVIDED FUNCTIONS

=head2 values

    (values <hash> <key-list>)
    (values <list> <idx-list>)
    (values <list>)
    (values <hash>)

This function returns the values of a compound data structure, such as a hash or
array reference. It optionally takes a list of keys (or indexes in case of an array).

You should only use this without a list of keys if you don't care about the order.

=head3 values Setter

    (set! (values <hash> <keys>) <new-list>)
    (set! (values <list> <indexes>) <new-list>)
    (set! (values <list>) <new-list>)

This setter will replace values in a compound data structure with new ones. Hashes
have to receive a key list, otherwise we'd run into order issues.

The list of new values must also be of the same size as the replaced section. For
lists without an index list, this is the size of the list itself. For all others, the
number of elements in the new value list must be the same as the number of keys or
indexes. Some examples:

    (define myhash { x: 3 y: 4 z: 5 })
    (define mylist `(1 2 3 4))

    (set! (values myhash `(x z)) `(7 8))
    ; myhash is now { x: 7 y: 4 z: 8 }

    (set! (values mylist) `(3 4 5 6))
    ; mylist is now (3 4 5 6)

    (set (values mylist `(1 2)) `(7 8))
    ; mylist is now (3 7 8 6)

=head2 defined?

    (defined? ...)

This predicate function takes one or more arguments and assures that all of them are
defined. It will return an undefined value if no arguments are passed.

=head2 reverse

    (reverse <hash>)
    (reverse <list>)
    (reverse <string>)

Sometimes you need to reverse some data. This function can take a single list, hash or
string and return its reversal. This works the same way as Perl does. A list as
argument leads to a new list with a reversed order of elements. The same happens with
a string but with characters instead of elements. Since hashes don't have orderings, a
reversal of a hash is a swap of the key/value pairs.

Some examples:

    (reverse "abc")         => "cba"
    (reverse `(1 2 3))      => (3 2 1)
    (reverse { x: 3 y: 4 }) => { 3 "x" 4 "y" }

=head2 length

    (length <string>)
    (length <list>)
    (length <hash>)

This function calculates the length of either a list, a hash or a string. With lists
the count of elements is returned, with a hash the number of key/value pairs, and with
a string the number of characters according to perl's C<length>.

=head2 empty?

    (empty? <value> ...)

This function will test if all of its arguments are empty. Will return a true value if
no arguments were specified. An item is empty if:

=over

=item * for hashes:

There are no keys.

=item * for lists:

The list has no elements.

=item * for strings:

The string has zero length. C<0> is not empty.

=item * for all other values:

If the value is undefined.

=back

=head2 keys

    (keys <hash>)
    (keys <list>)

This function takes a single compound argument and returns a list of keys (or indexes
if a list was passed):

    (keys `(3 4 5))         => (0 1 2)
    (keys { x: 3 y: 4 })    => ("x" "y") or ("y" "x")

As usual with Perl, hash key order is undefined.

=head2 exists?

    (exists? <data> <path-item> ...)

This is the function to test existance in all compound structures. It is rather easy.
Imagine the following data structure:

    (define data
        { users: 
            (list { name: "foo" }
                  { name: "bar" })
          admins:
            (list { name: "baz" }
                  { name: "qux" }) })

You could check if the second user has a name with the code:

    (exists? data :users 1 :name)

This is basically the same as Perl's

    exists $data->{users}[1]{name}

See L</at> for an explanation on the differences in Perl's and Template::SX's
behaviour. When the item to be checked is an object, one of two things might happen:

=over

=item * If the object is the last element in the path:

If the object is encountered at the end of the path, only a call to C<can> will be
performed to make sure a method of that name is available. This means that this code:

    (exists? obj :foo)

will test if the C<obj> has a method called C<foo>. It will return a boolean value. If
you want to get at the code reference, you will have to call C<can> yourself.

=item * If there are more path items to test:

When you have specified further path items beyond the object, the method will be called
and the path is continued on the methods return value. As an example:

    (exists? obj :foo :bar)

This would B<call> the C<foo> method on C<obj> without arguments, and test the existance
of a C<bar> key in the methods return value.

=back

=head2 at

    (at <data> <path-item> ...)

This returns the value in the data structure at the specific path. The format
is exactly the same as with L</exists?>.

Unlike C<exists?> when an object is encountered the methods are always called. Even if
its the final item in the path.

There are a couple of differences between how L<Template::SX> and Perl handle deep
structure access. This holds true for C<at> and L</exists?>. The differences are:

=over

=item * You don't need to worry about the type.

If you want to make sure a value is of a certain type, make the required checks
yourself. This has the advantage that together with C<apply> you can pass around
data access paths as first class values:

    (define (deep-join sep data . paths)
      (join sep
            (map paths
                 (-> (apply at data _)))))

    (define mydata
      { users:  (list { name: "foo" }
                      { name: "bar" })
        admins: (list { name: "baz" tags: (list "tag1" "tag2") }
                      { name: "qux" }) })

    ; generates "foo, bar, tag1"
    (deep-join ", " mydata
      `(users 0 name)
      `(users 1 name)
      `(admins 0 tags 0))

=item * It won't autovivify the tested structure.

If you want to change the datastructure, you will have to do it explicitely. Both
C<at> and L</exists?> will return an undefined value as soon as a path item was not
found as key.

=back

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Template::SX::Library::Data::Common> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Library::Data>

=item * L<Template::SX::Library::ScopeHandling>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut