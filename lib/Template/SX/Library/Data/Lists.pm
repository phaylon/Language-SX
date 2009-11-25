use MooseX::Declare;

class Template::SX::Library::Data::Lists extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use List::AllUtils          qw( first reduce any all );
    use List::MoreUtils         qw( any all );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_functions(list => sub { [@_] });

    CLASS->add_functions('list?' => CLASS->wrap_function('list?', { min => 1 }, sub {
        return scalar(grep { ref($_) ne 'ARRAY' } @_) ? undef : 1;
    }));

    CLASS->add_functions('list-ref', CLASS->wrap_function('list-ref', { min => 2, max => 2, types => [qw( list )] }, sub {
        return $_[0]->[ $_[1] ];
    }));
    CLASS->add_setter('list-ref', CLASS->wrap_function('list-ref', { min => 2, max => 2, types => [qw( list )] }, sub {
        my ($ls, $idx) = @_;
        return sub { $ls->[ $idx ] = shift };
    }));

    CLASS->add_functions(
        'any?'  => CLASS->wrap_function('any?', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return scalar( any { apply_scalar apply => $apply, arguments => [$_] } @$ls ) ? 1 : undef;
        }),
        'all?'  => CLASS->wrap_function('all?', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return scalar( all { apply_scalar apply => $apply, arguments => [$_] } @$ls ) ? 1 : undef;
        }),
    );

    CLASS->add_functions(
        gather => CLASS->wrap_function('gather', { min => 1, types => [qw( lambda )] }, sub {
            my ($collector, @args) = @_;

            my @collected;
            my $taker = sub { push @collected, @_ };

            apply_scalar apply => $collector, arguments => [$taker, @args];

            return \@collected;
        }),
    );

    CLASS->add_functions(
        'n-at-a-time' => CLASS->wrap_function('n-at-a-time', { min => 3, max => 3, types => [qw( any list applicant )] }, sub {
            my ($num, $ls, $apply) = @_;

            my $offset = 0;
            my @collected;

            while ($offset <= $#$ls) {

                push @collected, apply_scalar
                    apply       => $apply,
                    arguments   => [@{ $ls }[ $offset .. $offset + $num - 1 ]];

                $offset += $num;
            }

            return \@collected;
        }),
    );

    my $reformat_splice = sub {
        my ($ls, $start, $length) = @_;

        my $prepend = 0;
        my $append  = 0;

        my $fix_start = sub {

            if ($start < 0) {

                $prepend += abs($start);
                $start = 0;
            }
        };

        if ($start < 0) {

            $length = abs($start)
                unless defined $length;

            $start = scalar(@$ls) - abs($start);
        }

        $fix_start->();

        $length = scalar(@$ls) 
            unless defined $length;

        if ($length < 0) {

            $length = abs $length;
            $start -= ($length - 1);
        }

        $fix_start->();

        $length -= $prepend;
        $length = 0 
            if $length < 0;

        $length = scalar(@$ls) - $start
            if scalar(@$ls) < ($start + $length);

        return($start, ($start + ($length - 1)));
    };

    CLASS->add_functions(
        'list-splice' => CLASS->wrap_function('list-splice', { min => 2, max => 3, types => [qw( list )] }, sub {
            my ($ls, $start, $length) = @_;
            
            my ($first, $last) = $reformat_splice->($ls, $start, $length);
            return [ @{ $ls }[$first .. $last] ];
        }),
    );

    CLASS->add_setter(
        'list-splice' => CLASS->wrap_function('list-splice', { min => 2, max => 3, types => [qw( list )] }, sub {
            my ($ls, $start, $length) = @_;

            my ($first, $last) = $reformat_splice->($ls, $start, $length);

            return sub {
                my $new = shift;
                
                E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => 'list-splice setter expects to receive a list as value' },
                ) unless ref $new eq 'ARRAY';

                @$ls = (
                    @{ $ls }[0 .. $first - 1],
                    @$new,
                    @{ $ls }[($last + 1) .. $#$ls],
                );
            };
        }),
    );

    CLASS->add_functions(
        'for-each' => CLASS->wrap_function('for-each', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;

            apply_scalar apply => $apply, arguments => [$ls->[ $_ ]]
                for 0 .. $#$ls;

            return undef;
        }),
    );

    CLASS->add_functions(
        map     => CLASS->wrap_function('map', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return [ map { apply_scalar apply => $apply, arguments => [$_] } @$ls ];
        }),
        first   => CLASS->wrap_function('grep', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return scalar first { apply_scalar apply => $apply, arguments => [$_] } @$ls;
        }),
        grep    => CLASS->wrap_function('grep', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return [ grep { apply_scalar apply => $apply, arguments => [$_] } @$ls ];
        }),
        sort    => CLASS->wrap_function('sort', { min => 2, max => 2, types => [qw( list lambda )] }, sub {
            my ($ls, $apply) = @_;
            return [ sort { apply_scalar apply => $apply, arguments => [$a, $b] } @$ls ];
        }),
        append  => CLASS->wrap_function('append', { all_type => 'compound' }, sub {
            return [ map { (ref eq 'ARRAY') ? (@$_) : (%$_) } @_ ];
        }),
        join    => CLASS->wrap_function('join', { min => 2, max => 2, types => [qw( any list )] }, sub {
            return join($_[0], @{ $_[1] });
        }),
        head    => CLASS->wrap_function('head', { min => 1, max => 1, types => [qw( list )] }, sub {
            return $_[0]->[0];
        }),
        tail    => CLASS->wrap_function('tail', { min => 1, max => 1, types => [qw( list )] }, sub {
            return [ @{ $_[0] }[1 .. $#{ $_[0] }] ];
        }),
        reduce  => CLASS->wrap_function('reduce', { min => 2, max => 2, types => [qw( list lambda )] }, sub {
            my ($ls, $apply) = @_;
            return scalar reduce { apply_scalar apply => $apply, arguments => [$a, $b] } @$ls;
        }),
        uniq    => CLASS->wrap_function('uniq', { min => 1, max => 2, types => [qw( list lambda )] }, sub {
            my ($ls, $get_value) = @_;

            my @found;
            my %seen;

            for my $item (@$ls) {

                my $value = $get_value 
                    ? apply_scalar(apply => $get_value, arguments => [$item])
                    : "$item";

                next if $seen{ $value }++;

                push @found, $item;
            }

            return \@found;
        }),
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Data
@see_also Template::SX::Library::ScopeHandling
@license  Template::SX

@class Template::SX::Library::Data::Lists
All functionality concerning lists

@SYNOPSIS

    ; create a new list
    (list foo (+ bar baz) qux)

    ; predicate
    (if (list? foo)
      "foo is a list"
      "foo is not a list")

    ; accessing value at 3rd index
    (list-ref ls 3)

    ; changing value at 3rd index
    (set! (list-ref ls 3) 23)

    ; testing if any value conforms
    (any? ls even?

    ; testing if all values conform
    (all? ls odd?)

    ; gathering values
    (gather
      (lambda (take)
        (take 23)
        (take 7 8 9)))      ; => (23, 7, 8, 9)

    ; chunking a list, returns ({ x: 3 } { y: 4 })
    (n-at-a-time 2 (list x: 3 y: 4) (lambda (k v) { k v }))

    ; getting a list splice
    (list-splice '(1 2 3 4 5) 1 2)      ; => (2, 3)
    (list-splice '(1 2 3 4 5) 3)        ; => (4, 5)

    ; setting a list splice
    (define spliced '(1 2 3 4 5 6 7))
    (set! (list-splice spliced 1 2) '(9 8 7))
                    ; => now (1 9 8 7 4 5 6 7)
    (set! (list-splice spliced 5) '(23 24))
                    ; => now (1 9 8 7 4 23 24)

    ; do something for every item
    (for-each items (-> (_ :print)))

    ; map a list to another list with values increased by one
    (map ls (-> (++ _)))
    
    ; find the first item that is a list
    (first ls list?)

    ; find all even items in a list
    (grep ls even?)

    ; sort a list alphabetically
    (sort ls cmp)
    (sort ls (lambda (a b) (cmp a b)))

    ; append two lists into a new one
    (append '(1 2 3) '(4 5 6))
                        ; => (1 2 3 4 5 6)

    ; create a one level copy of a list
    (append ls)

    ; join a list into a string
    (join ", " ls)

    ; get the first element
    (head '(1 2 3 4))
                        ; => 1

    ; get all elements but the first
    (tail '(1 2 3 4))
                        ; => (2 3 4)

    ; classic reduce
    (reduce '(1 2 3) +)
                        ; => 6

    ; unique elements
    (uniq names)
    (uniq objects (-> (_ :name)))

@DESCRIPTION
This library contains all the extensions necessary to work with lists. This includes
creation, introspection and manipulation.

!TAG<lists>

=head1 PROVIDED FUNCTIONS

=head2 list

    (list ...)

This function will create a new list containing all passed arguments as elements:

    (list 1 2 3)    ; => (1 2 3)

=head2 list?

    (list? <item> ...)

This predicate function will return true if all of its arguments are lists and an undefined
value otherwise.

!TAG<type predicate>

=head2 list-ref

    (list-ref <list> <index>)

Returns the item at position C<index> from the C<list>.

=head3 list-ref Setter

    (set! (list-ref <list> <index>) <new-value>)

This will change the value in the C<list> at position C<index> to the C<new-value>.

!TAG<setter>

=head2 any?

    (any? <list> <test>)

This predicate function will return true if I<any> of the items in C<list> returned true
when passed to the C<test>:

    ; does ns contain even numbers?
    (any? ns even?)

The C<test> can also be an object. If it is, the value will be used as method like usual with
object applications:

    (any? '(:foo :bar) obj)

will check if C<(obj :foo)> or C<(obj :bar)> return true.

=head2 all?

    (all? <list> <test>)

This predicate function will return true if I<all> of the items in C<list> returned true
when passed to the C<test>:

    ; are all args lists?
    (all? args list?)

This also works with objects just like L</"any?">

=head2 gather

    (gather <collector>)

Since L<Template::SX> does not have a syntax even close to Perl (5 or 6), a C<gather/take>
implementation must look a bit different. Whenever possible I try to not introduce new functions
or syntax elements that would only work in a specific scope below another invocation. This is
one of the reasons why this C<gather> expects to receive a code reference. This code reference
will receive one argument: another code reference that can be used to C<take> items into the
collection:

    ; this will collect all $obj->name or $hashref->{name} (in Perl terms)
    (gather
      (lambda (take-name)
        (for-each items
          (lambda (item)
            (cond [(hash? item)
                   (take-name (hash-ref item :name))]
                  [(object? item)
                   (take-name (item :name))])))))

In the above, C<take-name> will be a code reference that will push all its arguments on to
the collection. C<gather> will return a list of all collected values when the collector
callback is done.

Another reason for the function argument is that this makes the collection extendable:

    ; imagine an object
    (define article (get-article id))

    ; this fetches all links from the article
    (define (collect-links take-links)
      (apply take-links (article :links)))

    ; collector extension that adds some default links
    (define ((collect-with-defaults next) take-links)
      (take-links
        (uri-for "/home")
        (uri-for "/private/admin")
        (uri-for "/contact"))
      (next take-links))

    ; collector extensino that fill only take certain links
    (define ((collect-with-filter next filter) take-links)
      (next 
        (lambda collected-links
          (apply take-links (grep collected-links filter)))))

    ; determines if a links is private
    (define (public? link)
      (not (link :is-private)))

    ; simply collect all llinks
    (gather collect-links)

    ; collect all links and add some defaults
    (gather (collect-with-defaults collect-links))

    ; collect all links but filter out private ones
    (gather 
      (collect-with-filter 
        collect-links 
        public?))

    ; collect all links including defaults and out filter private ones
    (gather 
      (collect-with-filter 
        (collect-with-defaults collect-links) 
        public?))

    ; collect all links and add defaults after they were filtered
    (gather 
      (collect-with-defaults 
        (collect-with-filter collect-links public?)))

!TAG<value collection>

=head2 n-at-a-time

    (n-at-a-time <count> <list> <applicant>)

This function will break the C<list> up in sets of C<count> values each. These values
will then be passed as arguments to the C<applicant>. The return value will be a list
containing all the return values of the invocations of the C<applicant>. The following
example would transform a list of keys and values into a list of single-key hash
references:

    (n-at-a-time 
      2
      '(x: 2 y: 3 z: 4)
      (lambda (k v) { k v }))

    ; => ({ x: 2 } { y: 3 } { z: 4 })

Since the last argument can be any applicant, you can also pass in an object:

    (n-at-a-time
      2
      '(foo: 23 bar: 42)
      obj)

The above would call the C<foo> method with C<23> as argument and C<bar> with C<42>. The 
result would contain the return values of both methods.

=head2 list-splice

    (list-splice <list> <start>)
    (list-splice <list> <start> <length>)

This function will take a C<list> and return a new list with the items beginning at C<start>.
The values will be limited by the optional C<length> parameter. If the C<length> is omitted,
all elements from C<start> to the end will be returned:

    (list-splice '(1 2 3 4) 1)      ; => (2 3 4)
    (list-splice '(1 2 3 4) 1 2)    ; => (2 3)

Only elements that really exist will be returned. If your C<length> is larger than the number
of available elements, only the really existing elements will be returned:

    (list-splice '(1 2 3 4) 2 5)    ; => (3 4)

You can specify a negative C<start> value to count from the end of the list:

    (list-splice '(1 2 3 4) -2)     ; (3 4)
    (list-splice '(1 2 3 4) -2 1)   ; (3)

The C<length> value can be negative as well. This means to take the elements I<before> the
C<start> position:

    (list-splice '(1 2 3 4) 2 -2)   ; (2 3)
    (list-splice '(1 2 3 4) -2 -2)  ; (2 3)

=head3 list-splice Setter

    (set! (list-splice <start>) <new-values>)
    (set! (list-splice <start> <length>) <new-values>)

This !TAGGED<setter> works just like the function of the same name above, but it will replace the
targetted set of elements instead of returning it. The C<new-values> always have to be
in form of a list.

=head2 for-each

!TAG<iteration>

    (for-each <list> <applicant>)

Use this instead of L</map> if you don't care about the calculated values. This function
will simply invoke the C<applicant> with each value in the C<list> and return an undefined
value.

=head2 map

    (map <list> <applicant>)

This function will pass each value in the C<list> to the C<applicant> and return a list
containing the return values of all invocations:

    (map '(1 2 3) ++)   ; => (2 3 4)

!TAG<sequential mapping>
!TAG<iteration>

=head2 first

    (first <list> <applicant>)

This will return the first value in C<list> that returns true when passed to the C<applicant>.

=head2 grep

    (grep <list> <test-applicant>)

Returns a new list containing all items in the passed C<list> that returned true when they were
passed to the C<test-applicant>.

!TAG<filtering>

=head2 sort

    (sort <list> <applicant>)

This function will return a sorted list containing the items in the C<list> based on the return
value of the C<applicant>. This C<sort> basically works like Perl's sort builtin. The applicant
should return C<-1>, C<0> or C<1>. See L<Template::SX::Library::Data::Strings/cmp> for alphabetic
sorting and L<Template::SX::Library::Data::Numbers/"E<lt>=E<gt>"> for numeric sorting.

!TAG<order determination>

=head2 append

    (append <list-or-hash> ...)

Takes any number of lists or hashes and returns a new list containing all elements of all passed lists:

    (append '(1 2 3) '(4 5 6))  ; => (1 2 3 4 5 6)

If only one list is passed, this is essentially a copy. If no arguments are present at all, it
will simply return a new empty list.

=head2 join

    (join <separator> <list>)

This works pretty much the same as Perl's C<join> builtin, except that this function takes an
array reference as second argument.

=head2 head

    (head <list>)

The head of the C<list> is the first element, or an undefined value if no elements were present.

=head2 tail

    (tail <list>)

The tail of the C<list> is returned as a new list containing all elements but the first.

=head2 reduce

    (reduce <list> <applicant>)

This is an implementation based on L<List::Util>s C<reduce>. The C<applicant> will receive two
arguments each time and a single value to which the list was reduced will be returned.

=head2 uniq

    (uniq <list>)
    (uniq <list> <unique-id-getter-applicant>)

When used without a getter, C<uniq> will return a new list containing all the items in the passed
C<list> that were unique by string. If a getter applicant is specified, it will receive the item 
that is tested and must return the unique id for that item. For example, to get all unique objects
when they have an C<id> method do this:

    (uniq objects (-> (_ :id)))

=end fusion






=head1 NAME

Template::SX::Library::Data::Lists - All functionality concerning lists

=head1 SYNOPSIS

    ; create a new list
    (list foo (+ bar baz) qux)

    ; predicate
    (if (list? foo)
      "foo is a list"
      "foo is not a list")

    ; accessing value at 3rd index
    (list-ref ls 3)

    ; changing value at 3rd index
    (set! (list-ref ls 3) 23)

    ; testing if any value conforms
    (any? ls even?

    ; testing if all values conform
    (all? ls odd?)

    ; gathering values
    (gather
      (lambda (take)
        (take 23)
        (take 7 8 9)))      ; => (23, 7, 8, 9)

    ; chunking a list, returns ({ x: 3 } { y: 4 })
    (n-at-a-time 2 (list x: 3 y: 4) (lambda (k v) { k v }))

    ; getting a list splice
    (list-splice '(1 2 3 4 5) 1 2)      ; => (2, 3)
    (list-splice '(1 2 3 4 5) 3)        ; => (4, 5)

    ; setting a list splice
    (define spliced '(1 2 3 4 5 6 7))
    (set! (list-splice spliced 1 2) '(9 8 7))
                    ; => now (1 9 8 7 4 5 6 7)
    (set! (list-splice spliced 5) '(23 24))
                    ; => now (1 9 8 7 4 23 24)

    ; do something for every item
    (for-each items (-> (_ :print)))

    ; map a list to another list with values increased by one
    (map ls (-> (++ _)))
    
    ; find the first item that is a list
    (first ls list?)

    ; find all even items in a list
    (grep ls even?)

    ; sort a list alphabetically
    (sort ls cmp)
    (sort ls (lambda (a b) (cmp a b)))

    ; append two lists into a new one
    (append '(1 2 3) '(4 5 6))
                        ; => (1 2 3 4 5 6)

    ; create a one level copy of a list
    (append ls)

    ; join a list into a string
    (join ", " ls)

    ; get the first element
    (head '(1 2 3 4))
                        ; => 1

    ; get all elements but the first
    (tail '(1 2 3 4))
                        ; => (2 3 4)

    ; classic reduce
    (reduce '(1 2 3) +)
                        ; => 6

    ; unique elements
    (uniq names)
    (uniq objects (-> (_ :name)))

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Data::Lists

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

This library contains all the extensions necessary to work with lists. This includes
creation, introspection and manipulation.

=head1 PROVIDED FUNCTIONS

=head2 list

    (list ...)

This function will create a new list containing all passed arguments as elements:

    (list 1 2 3)    ; => (1 2 3)

=head2 list?

    (list? <item> ...)

This predicate function will return true if all of its arguments are lists and an undefined
value otherwise.

=head2 list-ref

    (list-ref <list> <index>)

Returns the item at position C<index> from the C<list>.

=head3 list-ref Setter

    (set! (list-ref <list> <index>) <new-value>)

This will change the value in the C<list> at position C<index> to the C<new-value>.

=head2 any?

    (any? <list> <test>)

This predicate function will return true if I<any> of the items in C<list> returned true
when passed to the C<test>:

    ; does ns contain even numbers?
    (any? ns even?)

The C<test> can also be an object. If it is, the value will be used as method like usual with
object applications:

    (any? '(:foo :bar) obj)

will check if C<(obj :foo)> or C<(obj :bar)> return true.

=head2 all?

    (all? <list> <test>)

This predicate function will return true if I<all> of the items in C<list> returned true
when passed to the C<test>:

    ; are all args lists?
    (all? args list?)

This also works with objects just like L</"any?">

=head2 gather

    (gather <collector>)

Since L<Template::SX> does not have a syntax even close to Perl (5 or 6), a C<gather/take>
implementation must look a bit different. Whenever possible I try to not introduce new functions
or syntax elements that would only work in a specific scope below another invocation. This is
one of the reasons why this C<gather> expects to receive a code reference. This code reference
will receive one argument: another code reference that can be used to C<take> items into the
collection:

    ; this will collect all $obj->name or $hashref->{name} (in Perl terms)
    (gather
      (lambda (take-name)
        (for-each items
          (lambda (item)
            (cond [(hash? item)
                   (take-name (hash-ref item :name))]
                  [(object? item)
                   (take-name (item :name))])))))

In the above, C<take-name> will be a code reference that will push all its arguments on to
the collection. C<gather> will return a list of all collected values when the collector
callback is done.

Another reason for the function argument is that this makes the collection extendable:

    ; imagine an object
    (define article (get-article id))

    ; this fetches all links from the article
    (define (collect-links take-links)
      (apply take-links (article :links)))

    ; collector extension that adds some default links
    (define ((collect-with-defaults next) take-links)
      (take-links
        (uri-for "/home")
        (uri-for "/private/admin")
        (uri-for "/contact"))
      (next take-links))

    ; collector extensino that fill only take certain links
    (define ((collect-with-filter next filter) take-links)
      (next 
        (lambda collected-links
          (apply take-links (grep collected-links filter)))))

    ; determines if a links is private
    (define (public? link)
      (not (link :is-private)))

    ; simply collect all llinks
    (gather collect-links)

    ; collect all links and add some defaults
    (gather (collect-with-defaults collect-links))

    ; collect all links but filter out private ones
    (gather 
      (collect-with-filter 
        collect-links 
        public?))

    ; collect all links including defaults and out filter private ones
    (gather 
      (collect-with-filter 
        (collect-with-defaults collect-links) 
        public?))

    ; collect all links and add defaults after they were filtered
    (gather 
      (collect-with-defaults 
        (collect-with-filter collect-links public?)))

=head2 n-at-a-time

    (n-at-a-time <count> <list> <applicant>)

This function will break the C<list> up in sets of C<count> values each. These values
will then be passed as arguments to the C<applicant>. The return value will be a list
containing all the return values of the invocations of the C<applicant>. The following
example would transform a list of keys and values into a list of single-key hash
references:

    (n-at-a-time 
      2
      '(x: 2 y: 3 z: 4)
      (lambda (k v) { k v }))

    ; => ({ x: 2 } { y: 3 } { z: 4 })

Since the last argument can be any applicant, you can also pass in an object:

    (n-at-a-time
      2
      '(foo: 23 bar: 42)
      obj)

The above would call the C<foo> method with C<23> as argument and C<bar> with C<42>. The 
result would contain the return values of both methods.

=head2 list-splice

    (list-splice <list> <start>)
    (list-splice <list> <start> <length>)

This function will take a C<list> and return a new list with the items beginning at C<start>.
The values will be limited by the optional C<length> parameter. If the C<length> is omitted,
all elements from C<start> to the end will be returned:

    (list-splice '(1 2 3 4) 1)      ; => (2 3 4)
    (list-splice '(1 2 3 4) 1 2)    ; => (2 3)

Only elements that really exist will be returned. If your C<length> is larger than the number
of available elements, only the really existing elements will be returned:

    (list-splice '(1 2 3 4) 2 5)    ; => (3 4)

You can specify a negative C<start> value to count from the end of the list:

    (list-splice '(1 2 3 4) -2)     ; (3 4)
    (list-splice '(1 2 3 4) -2 1)   ; (3)

The C<length> value can be negative as well. This means to take the elements I<before> the
C<start> position:

    (list-splice '(1 2 3 4) 2 -2)   ; (2 3)
    (list-splice '(1 2 3 4) -2 -2)  ; (2 3)

=head3 list-splice Setter

    (set! (list-splice <start>) <new-values>)
    (set! (list-splice <start> <length>) <new-values>)

This setter works just like the function of the same name above, but it will replace the
targetted set of elements instead of returning it. The C<new-values> always have to be
in form of a list.

=head2 for-each

    (for-each <list> <applicant>)

Use this instead of L</map> if you don't care about the calculated values. This function
will simply invoke the C<applicant> with each value in the C<list> and return an undefined
value.

=head2 map

    (map <list> <applicant>)

This function will pass each value in the C<list> to the C<applicant> and return a list
containing the return values of all invocations:

    (map '(1 2 3) ++)   ; => (2 3 4)

=head2 first

    (first <list> <applicant>)

This will return the first value in C<list> that returns true when passed to the C<applicant>.

=head2 grep

    (grep <list> <test-applicant>)

Returns a new list containing all items in the passed C<list> that returned true when they were
passed to the C<test-applicant>.

=head2 sort

    (sort <list> <applicant>)

This function will return a sorted list containing the items in the C<list> based on the return
value of the C<applicant>. This C<sort> basically works like Perl's sort builtin. The applicant
should return C<-1>, C<0> or C<1>. See L<Template::SX::Library::Data::Strings/cmp> for alphabetic
sorting and L<Template::SX::Library::Data::Numbers/"E<lt>=E<gt>"> for numeric sorting.

=head2 append

    (append <list-or-hash> ...)

Takes any number of lists or hashes and returns a new list containing all elements of all passed lists:

    (append '(1 2 3) '(4 5 6))  ; => (1 2 3 4 5 6)

If only one list is passed, this is essentially a copy. If no arguments are present at all, it
will simply return a new empty list.

=head2 join

    (join <separator> <list>)

This works pretty much the same as Perl's C<join> builtin, except that this function takes an
array reference as second argument.

=head2 head

    (head <list>)

The head of the C<list> is the first element, or an undefined value if no elements were present.

=head2 tail

    (tail <list>)

The tail of the C<list> is returned as a new list containing all elements but the first.

=head2 reduce

    (reduce <list> <applicant>)

This is an implementation based on L<List::Util>s C<reduce>. The C<applicant> will receive two
arguments each time and a single value to which the list was reduced will be returned.

=head2 uniq

    (uniq <list>)
    (uniq <list> <unique-id-getter-applicant>)

When used without a getter, C<uniq> will return a new list containing all the items in the passed
C<list> that were unique by string. If a getter applicant is specified, it will receive the item 
that is tested and must return the unique id for that item. For example, to get all unique objects
when they have an C<id> method do this:

    (uniq objects (-> (_ :id)))

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Template::SX::Library::Data::Lists> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Data>

=item * L<Template::SX::Library::ScopeHandling>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut