use MooseX::Declare;

class Template::SX::Library::Types extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Name                       qw( subname );
    use TryCatch;
    use Data::Dump                      qw( pp );
    use Template::SX::Constants         qw( :all );
    use Template::SX::Util              qw) :all );
    use Moose::Util::TypeConstraints    qw( find_type_constraint subtype enum duck_type class_type role_type message where as );
    use Scalar::Util                    qw( blessed );

    Class::MOP::load_class($_)
        for E_SYNTAX, E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';

    CLASS->add_functions(
        'union' => CLASS->wrap_function('any-type', { min => 1, all_type => 'type' }, sub {
            return shift if @_ == 1;
            require Moose::Meta::TypeConstraint::Union;
            return Moose::Meta::TypeConstraint::Union->new(
                type_constraints => [@_],
            );
        }),
        'enum' => CLASS->wrap_function('enum', { min => 1 }, sub {
            return enum [map { "$_" } @_];
        }),
        'enum->list' => CLASS->wrap_function('enum->list', { min => 1, max => 1, types => [qw( enum )] }, sub {
            return [ @{ $_[0]->values } ];
        }),
        'list->enum' => CLASS->wrap_function('list->enum', { min => 1, max => 1, types => [qw( list )] }, sub {
            return enum [ map { "$_" } @{ $_[0] } ];
        }),
    );

    CLASS->add_functions(
        'type?' => CLASS->wrap_function('type?', { min => 1 }, sub { 
            return scalar(grep { not( blessed($_) and $_->isa('Moose::Meta::TypeConstraint') ) } @_) ? undef : 1;
        }),
        'is?' => CLASS->wrap_function('is?', { min => 1, types => [qw( type )] }, sub {

            my $tc   = shift;
            my $pred = sub {

                E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => "predicate generated with is? for $tc requires at least one value to test" },
                ) unless @_;

                for (@_) {
                    return undef unless $tc->check($_);
                }

                return 1;
            };

            return @_ ? $pred->(@_) : $pred;
        }),
        'coerce' => CLASS->wrap_function('coerce', { min => 2, max => 2, types => [qw( type )] }, sub {
            my ($tc, $val) = @_;
            return scalar $tc->coerce($val);
        }),
        'subtype' => CLASS->wrap_function('subtype', { min => 1, types => [qw( type )] }, sub {
            my ($tc, %args) = @_;

            my ($where, $message) = map { delete $args{ $_ } } qw( where message );

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => sprintf 'unknown subtype options: %s', join ' ', keys %args },
            ) if keys %args;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'where clause value is expected to be a code reference' },
            ) if defined($where) and not ref($where) eq 'CODE';

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'message option value is expected to be a code reference or string' },
            ) if defined($message) and not( ref($message) eq 'CODE' or not ref($message) );

            return subtype(
                as $tc,
              ( defined($where)     ? where { $where->($_) }
                : () ),
              ( defined($message)   ? message { ref($message) ? $message->($_) : $message }
                : () ),
            );
        }),
    );

    CLASS->add_syntax('import/types', sub {
        my $self = shift;
        my $inf  = shift;
        my $cell = shift;

        E_SYNTAX->throw(
            message     => 'import/types expects at least one import specification',
            location    => $cell->location,
        ) unless @_;

        my @spec = map {
            my $import = $_;
            my $res;

            if ($import->isa('Template::SX::Document::Cell::Application')) {

                E_SYNTAX->throw(
                    message     => 'import/types library specification needs library name and a list of types to import',
                    location    => $import->location,
                ) unless $import->node_count >= 2;

                my ($lib, @types) = $import->all_nodes;

                E_SYNTAX->throw(
                    message     => 'library name is expected to be a bareword',
                    location    => $lib->location,
                ) unless $lib->isa('Template::SX::Document::Bareword');

                $res = [
                    [$lib->value, $lib->location],
                    map {
                        my $type = $_;

                        E_SYNTAX->throw(
                            message     => 'type specification is expected to be a bareword',
                            location    => $type->location,
                        ) unless $type->isa('Template::SX::Document::Bareword');

                        [$type->value, $type->location];
                    } @types
                ];
            }
            elsif ($import->isa('Template::SX::Document::Bareword')) {

                $res = [[$import->value, $import->location]];
            }
            else {

                E_SYNTAX->throw(
                    message     => 'each element in import/types specification is expected to be a bareword or list',
                    location    => $import->location,
                ) unless $import->isa('Template::SX::Document::Cell::Application');
            }

            $res;
        } @_;

        return $inf->render_call(
            library => $CLASS,
            method  => 'make_type_import',
            args    => {
                import  => pp(\@spec),
            },
        );
    });

    method make_type_import (ArrayRef[ArrayRef] :$import!) {

        my @done_types;
        
      LIBRARY:
        for my $lib_spec (@$import) {
            my ($lib, @types)     = @$lib_spec;
            my ($name, $location) = @$lib;
            
            my @errors;
            my $found;
          TRY:
            for my $possible ("MooseX::Types::$name", $name) {
                
                try {
                    Class::MOP::load_class($possible);

                    E_INTERNAL->throw(
                        message     => "package $possible is not a MooseX::Types type library",
                        location    => $location,
                    ) unless $possible->isa('MooseX::Types::Base');

                    $found = $possible;
                }
                catch (Any $e) {

                    push @errors, $e;
                }

                if ($found) {
                    last TRY;
                }
            }

            E_INTERNAL->throw(
                message     => "unable to load a library named '$name':\n" . join("\n", @errors),
                location    => $location,
            ) unless $found;

            if (@types) {

                for my $type_spec (@types) {
                    my ($type_name, $type_location) = @$type_spec;

                    try {
                        push @done_types, [$type_name, find_type_constraint($found->get_type($type_name))];
                    }
                    catch (Any $e) {

                        E_INTERNAL->throw(
                            message     => "unable to load type '$type_name' from library '$found': $e",
                            location    => $type_location,
                        )
                    }
                }
            }
            else {

                push @done_types, [$_, find_type_constraint($found->get_type($_))]
                    for $found->type_names;
            }
        }

        return subname IMPORT_TYPES => sub {
            my $env = shift;

            $env->{vars}{ $_->[0] } = $_->[1]
                for @done_types;
        };
    }
}

__END__

=head1 NAME

Template::SX::Library::Types - Type functionality

=head1 SYNOPSIS

    ; importing types from a MooseX::Types library
    (import/types
      (Moose Str Int ArrayRef HashRef)  ; import only some
      Path::Class)                      ; import all

    ; parameterizing types
    (define MyList (ArrayRef Int))

    ; testing a value
    (if (is? ArrayRef foo)
      foo
      #f)

    ; coercing a value
    (define value
      (coerce MyTypeWithCoercions foo))

    ; creating an anonymous subtype
    (define NonEmptyStr
      (subtype Str
        where:   (-> (and (string? _) (not (empty? _))))
        message: "not a string or not empty"))

    ; type predicate
    (if (type? foo)
      "is a type"
      "is not a type")

    ; type unions
    (define StrOrList
      (union Str ArrayRef[Str]))

    ; enum types
    (define HTTPMethod
      (enum "post" "get" "put" "delete"))

    ; values in an enum
    (enum->list HTTPMethod)

    ; creating an enum from a list
    (list->enum (list "foo" "bar"))

=head1 DESCRIPTION

This library provides extensions necessary to operate with and on L<Moose type constraint|Moose::Manual::Types>
objects.

=head2 Type Constraints != Objects

At least when used in L<Template::SX>, type constraints are not regarded as objects. An invocation of a type
constraint will always invoke the parameterization, not the actual object. This means that:

    (ArrayRef Int)          ; will create a parameterized type
    (ArrayRef :check 3)     ; will most likely fail, same as ArrayRef[check => 3]

If you really need to invoke the type constraints object methods, use L<Template::SX::Library::Data::Objects/object-invocant>:

    ; call method 'check' on type object
    ((object-invocant (ArrayRef Int)) :check 3)

Besides this, type constraints are first class values as usual.

=head2 Where Types Come from

You will have to use L</"import/types"> to actually load type constraints into your namespace. There are no types provided by
default, and no strings will be accepted in place of a type constraint object.

=head2 Type Library Examples

=over

=item L<MooseX::Types::Moose>

    ; create an ArrayRef[HashRef[Int]]
    (import/types Moose)
    (define MyType (ArrayRef (HashRef Int)))

=item L<MooseX::Types::Path::Class>

    ; create a file inflator
    (import/types Path::Class)
    (define (inflate-file value)
      (coerce File value))

=item L<MooseX::Types::Structured>

    ; create a record
    (import/types Structured Moose Path::Class)
    (define PersonRecord
      (Dict :name   Str
            :image  (Tuple File Str)))

=back

=head1 PROVIDES SYNTAX ELEMENTS

=head2 import/types

  (import/types <import-spec> ...)

The C<import/types> syntax element is used to import L<Moose type constraint|Moose::Manual::Types> 
objects into the current lexical environment.

Valid constructs for C<import-spec> are barewords and lists containing a library name and a set of
types to import. As an example,

    (import/types Moose)

would import all type constraints declared in L<MooseX::Types::Moose>. If you wanted to only import
certain constraints, name them explicitely:

    (import/types (Moose Int Str))

This will only import the C<Int> and C<Str> type constraints.

When looking for a library by name C<import/types> will first try to load it prefixed with C<MooseX::Types::>.
This means that the name C<Moose> above will result in an attempt to use C<MooseX::Types::Moose> first, and a
package named C<Moose> later. L<Moose> itself isn't a type library, so it will be skipped. This means that if
you want to use a library from a different namespace than C<MooseX::Types::>, you can specify the full name
instead. This all means that

    (import/types MyProject::Types)

will first look for C<MooseX::Types::MyProject::Types> (which it will probably not find) and then load
C<MyProject::Types> if it exists.

You can specify multiple import specifications at once, like in the L</SYNOPSIS>:

    (import/types Structured Path::Class (Moose Int Str))


=head1 PROVIDES FUNCTIONS

=head2 type?

    (type? <value> ...)

Takes one or more values as argument and returns true if all of them are type constraints. If at least one
of them isn't it will return an undefined value. This function requires at least one argument.


=head2 is?

    (is? <type> <value> ...)
    (is? <type>)

This function performs two jobs. When it receives two or more arguments it will use the type constraint in the
first argument to check all other values passed in.

If there is only a single type argument, C<is?> will return a predicate code reference that will test all its
arguments against the closed over type constraint.

Here is an example of how to simply test if a value conforms to a type:

    (if (is? (ArrayRef Int) ls)
      (do-something-with ls)
      (do-something-else))

The above will execute C<do-something-with> with the C<ls> argument if C<ls> is an C<ArrayRef> of C<Int>s. If we
used it this way to grep a list, we would come up with something like this:

    (grep ls 
          (lambda (item) 
            (is? (ArrayRef Int) item)))

But we can also omit the value arguments to create a predicate code reference. This means we can shorten the above
to

    (grep ls (is? (ArrayRef Int)))

This also has the advantage of not recreating the parameterized type on every run.


=head2 coerce

    (coerce <type> <value>)

This function expects exactly two arguments. The first is the type we want to coerce to, the second is the value we
want to coerce. A simple real-life example would be:

    (import/types Path::Class)
    (define foo_path (coerce File "x/y/foo.txt"))   ; now a Path::Class::File

It is currently not yet possible to declare coercions withing L<Template::SX>.


=head2 subtype

    (subtype <type> where: <test-func> message: <message-func-or-string>)

This is a function that will take a C<type> constraint and return a new subtype based on it. it will optionally take
a C<where> and a C<message> option. If C<where> is specified it has to be a code reference that will receive the value
to test as its single argument. The C<message> can be either a code reference receiving the failed value or a string:

    (subtype Int 
      where:   even? 
      message: (-> "value ${_} is not an even integer"))


=head2 union

    (union <type> ...)

This function will create a type union containing all specified types. At least one type argument must be specified. If
there is only one argument, it will be returned without being wrapped in an union. 

To create a type that allows either an array or hash reference you can use this:

    (union ArrayRef HashRef)


=head2 enum

    (enum <value> ...)

This simply creates an enum out of the specified values like you know it from L<Moose|Moose::Manual::Types>. It expects
at least one value.

Example:

    ; foo or bar
    (enum "foo" "bar")


=head2 enum->list

    (enum->list <enum>)

This function takes a single enum type constraint and returns a list containing the values the enum is containing.

    ; returns [qw( foo bar )]
    (enum->list (enum "foo" "bar"))


=head2 list->enum

    (list->enum <list>)

This is basically the same as L</enum> but it takes a list as a single argument, instead of expecting the valid values
to be passed in as one argument each. You could also see this as the reverse of L</enum-L<gt>list>.

    ; these are the same
    (enum "foo" "bar")
    (list->enum (list "foo" "bar"))


=head1 SEE ALSO

L<Template::SX>,
L<Template::SX::Library::Data::Lists>,
L<Template::SX::Library::ScopeHandling>,
L<Moose::Manual::Types>,
L<MooseX::Types>

=cut
