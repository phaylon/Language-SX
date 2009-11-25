use MooseX::Declare;
use utf8;

class Template::SX {

    with 'MooseX::Traits';

    use Template::SX::Types         qw( :all );
    use Template::SX::Constants     qw( :all );
    use MooseX::Types::Moose        qw( CodeRef Str HashRef Bool ArrayRef );
    use MooseX::Types::Path::Class  qw( File Dir );
    use MooseX::MultiMethods;
    use MooseX::StrictConstructor;
    use Scalar::Util                qw( weaken );
    use Path::Class                 qw( file dir );

    BEGIN {
        if ($Template::SX::TRACK_INSTANCES) {
            require MooseX::InstanceTracking;
            MooseX::InstanceTracking->import;
        }
    }

    our $VERSION = '0.001';

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    has reader => (
        is          => 'ro', 
        isa         => 'Template::SX::Reader', 
        required    => 1, 
        lazy_build  => 1,
        handles     => {
            _document_from_string   => 'read',
            _stream_from_string     => 'create_stream',
        },
    );

    has default_libraries => (
        traits      => [qw( Array )],
        is          => 'ro',
        isa         => LibraryList,
        required    => 1,
        coerce      => 1,
        default     => sub { require Template::SX::Library::Core; [Template::SX::Library::Core->new] },
        handles     => {
            all_libraries   => 'elements',
        },
    );

    has document_traits => (
        is          => 'ro',
        isa         => ArrayRef[Str],
        required    => 1,
        default     => sub { [] },
    );

    has include_path => (
        is          => 'ro',
        isa         => Dir,
        default     => sub { dir '.' },
        required    => 1,
        coerce      => 1,
    );

    has use_global_cache => (
        is          => 'ro',
        isa         => Bool,
    );

    my %GlobalCache;

    has _document_cache => (
        is          => 'ro',
        isa         => HashRef,
        required    => 1,
        lazy        => 1,
        default     => sub { $_[0]->use_global_cache ? \%GlobalCache : {} },
    );

    has '+_trait_namespace' => (
        default     => 'Template::SX::Trait',
    );

    method _build_reader {

        require Template::SX::Reader;
        return Template::SX::Reader->new(
            document_libraries  => [@{ $self->default_libraries }],
            document_traits     => [@{ $self->document_traits }],
            document_loader     => (sub { 
                my $sx = shift;
                weaken $sx;
                return sub { $sx->read(file => $_[0]) };
            })->($self),
        );
    }

    method all_function_names () { map { ($_->function_names) } @{ $self->default_libraries } }
    method all_syntax_names   () { map { ($_->syntax_names) }   @{ $self->default_libraries } }


    method read (SourceType $type, Any $source, Str :$source_name?) {
        my $doc = $self->can("_read_${type}")->($self, $source, $source_name || ());
        $doc->_set_default_include_path($self->include_path);
        return $doc;
    }

    method _read_string (Str $source, Str $source_name?) {
        return $self->_document_from_string($source, $source_name || ());
    }

    method _read_file (File $source does coerce) {

        E_PROTOTYPE->throw(
            class       => E_FILE,
            attributes  => { message => "unable to load non-existing file $source", path => $source },
        ) unless -e $source;

        my @libs = map { blessed($_) } $self->all_libraries;
        my $key  = join '|', @libs;

        my $cache = $self->_document_cache;

        return $cache->{ $source }{ $key }
            if exists $cache->{ $source }{ $key };

        my $content = $source->slurp;

        return $cache->{ $source }{ $key } 
            = $self->_document_from_string($content, $source->absolute->stringify);
    }


    method run (SourceType $type, Any $source, HashRef :$vars = {}, Bool :$persist, Str :$source_name?) {

        my $doc = $self->read($type, $source, $source_name ? (source_name => $source_name) : ());

        return $doc->run(
            vars            => $vars, 
            persist         => $persist, 
            include_path    => $self->include_path,
        );
    }
}

__END__

=encoding utf-8

=begin fusion

=encoding utf8

@see_also Template::SX::Library::Core
@see_also Template::SX::Renderer::Plain
@license
Copyright 2009 (c) Robert Sedlacek (phaylon)

This library is free software; you can redistribute it and/or modify it under the same terms
as Perl 5.10.0.

@authors
Robert 'phaylon' Sedlacek, C<rs@474.at>

@class Template::SX
An S-Expression to Perl code inflator

@method all_function_names
Returns a list of all available functions in all libraries. This is mostly for easy
introspection like the REPL requires.

@method all_libraries
Returns all loaded libraries.

@method all_syntax_names
Returns a list of all syntax elements in all libraries. Mostly used for easy introspection
by the REPL.

@method read
%param $type            How to treat the C<$source> argument.
%param $source          The source of the code to read.
%param :$source_name    Name of the source, e.g. filename.
Reads a L<Template::SX::Document> from a C<$source> definition.

@method run
%param $type            How to treat the C<$source> argument.
%param $source          The source of the code to run.
%param :$persist        If true, the passed in C<$vars> will not be copied but modified instead.
%param :$source_name    Name of the source, e.g. filename.
%param :$vars           Initial variables for the code.
L<Reads|/read> a document and runs it.

@attr default_libraries
List of default library objects for new documents. Defaults to L<Template::SX::Library::Core>.

@attr document_traits
Traits that should be applied to new documents.

@attr include_path
Where to look for other C<Template::SX> files to load.

@attr reader
The reader object is used to translate code from text to a document.

@attr use_global_cache
If true, a process global storage for loaded documents will be used instead of recreating documents
each time. This can increase speeds drastically in long-running processes.

@SYNOPSIS

    my $sx  = Template::SX->new(use_global_cache => 1);
    my $res = $sx->run(file => $file, { somevalue => 23 });

@DESCRIPTION

C<Template::SX> is an implementation for executing S-Expression code in Perl. The used language is
loosely based on Scheme, but many things are different to make it all more Perlish and easier to
use side-by-side with Perl.

=head2 A Summary

Because you might be to impatient to read all the documentation to find out if this does what you want,
here is a quick checklist:

=over

=item *

No tail-call-C<$anything>. While internally some places might use C<goto> to optimize for space or
speed, no user code will be implicitely tailcalled. 

=item *

Lisp and with this also Scheme are list-based languages. C<Template::SX> implements more of a data
structure language, in that it also allows you to create (and quote) Perl hashes.

=item *

It's slower than pure Perl, obviously.

=item *

Special handling for L<Moose type constraints|Moose::Manual::Types> to better integrate them into the
language. They can be imported, passed around as usual, used in function signatures, nested, etc.

=item *

Comes with a very simple REPL.

=item *

Lexically scoped and currently closing over environments, not value containers.

=item *

Includes a simple rendering system with L<Template::SX::Renderer::Plain> that allows specially formed
data structures to be compiled to HTML.

=item *

Can do Scheme style quoting (C<'>), quasiquoting (C<`>), unquoting (C<,>) and splicing unquotes (C<,@>).

=back

=head2 Why would you do something like that?

Basically, I wanted something like SXML in Perl. S-Expressions provide an extremely concise way of
building tree structures.

=head2 Compilation and Execution

It's a long way from a piece of string to running code. These are the steps that are currently made on
the way:

=over

=item *

First the body is turned into a L<stream|Template::SX::Reader::Stream> by the
L<reader|Template::SX::Reader>.

=item *

The reader will then create a new L<document|Template::SX::Document>. This new document receives the previously 
created stream and inflates itself into a tree structure.

=item *

To compile the tree structure, the document will create an L<inflator|Template::SX::Inflator>. The purpose of
the inflator is to provide an environment for the tree structure to be compiled in. The structure will be
recursively compiled to an inflation body consisting of Perl code that builds callbacks. This inflation body
is what should be cached on the filesystem if needed.

=item *

When the inflation body is evaluated, it will return an optimised tree of combined code references. The document
can then call this code reference (along with providing a suitable environment and user provided arguments) to
calculate the result.

=back

=head1 THE LANGUAGE

=head2 General Syntax

In general it all looks like Scheme. You call something by putting it in a list:

!TAG<application>

    (+ 2 3)         ; returns 5

Code can also be nested:

    (+ (* 2 2) 3)   ; returns 7

The evaluation order is left-to-right, inner-to-outer. Syntax elements might change
the order of argument evaluation or omit their evaluation at all:

    (if (get-something)
      (do-something) 
      (do-something-else))

In the above code C<do-something> will only be executed if C<get-something> returns
true. Otherwise C<do-<omsething-else> will be called.

For a non-syntax application, all elements of the application list are dynamic, including
the one at the operator position. This means that this will work as you expect:

    ((if (eq? do :add)
       +
       *)
     2 3)

For all intents and purposes, C<()> and C<[]> are synonymous. You can use C<[]>
instead to make parts stand out visually:

    (let [(x 3)
          (y 4)]
      (+ x y))

Unlike most other Lisps that I know of, you can also specify hashes in-line:

    { x: 4 y: 5 }

See L<Template::SX::Library::Quoting> for details on how to build complex inline data
structures.

=head2 Context

Every call in C<Template::SX> is made in scalar context. If you really have to call 
something in list context, see L<Template::SX::Library::Data::Functions/"apply/list">
for information.

!TAG<context>

=head2 Data Types

!TAG<runtime value>

=head3 Numbers

Numbers are rather simple:

    (+ 3 -7 3.5 20_000 5.000_001 +7)

!TAG<math>

=head3 Strings

!TAG<strings>

Strings can either be constant like this:

    "foo"

or contain runtime interpolations like this:

    "foo ${ (+ x y) } bar"

And, while it might screw up your string-highlighting, you can have strings in
interpolated strings too:

    "foo ${ (join ", " names) } bar"

=head3 Regular Expressions

!TAG<regular expressions>

Regular expressions have a slightly different syntax in L<Template::SX> than in raw
Perl. First, they start with C<rx>:

    rx/foo/i

The regular expression is I<always> in C<x> mode, which means you always have to
specify spaces explicitely. There is currently no direct interpolation in regular
expressions.

See L<Template::SX::Library::Data::Regex> for details about regular expression
handling.

=head3 Lists

!TAG<lists>

Lists in a C<Template::SX> context refers to array references. Since there are no 
non-reference arrays in this system, and I didn't want to write "array reference" all
the time, I use both interchangably.

You can create lists with L<Template::SX::Library::Data::Lists/list> or by 
L<quoting|Template::SX::Library::Quoting> a C<()> or C<[]> structure.

=head3 Hashes

!TAG<hashes>

Hashes are always hash references. You can create them with
L<Template::SX::Library::Data::Hashes/hash> or with a (quoted or unquoted) C<{}> cell.

=head3 Objects

!TAG<objects>
1TAG<object methods>

You can invoke objects just like functions. You have to pass the method to call in as
first argument. These will all call C<foo> on C<obj>:

    (obj :foo ...)
    (obj "foo" ...)
    (obj 'foo ...)

The following will call the method specified in C<bar>:

    (obj bar ...)

You can replace the C<...> with the arguments you want to pass to the method. Just like
in Perl, if the method argument is a code reference, it will be used instead of a method
lookup:

    (obj list)

will return a list containing the object, since L<list|Template::SX::Library::Data::Lists/list>
is a builtin function constructing lists.

B<Note> that L<Moose type constraints|Moose::Manual::Types> are not treated as objects. They are
handled specially so you can say things like:

    (HashRef Int)

See L<Template::SX::Library::Types> for more information.

!TAG<type objects>

=head3 Keywords

!TAG<keywords>

A keyword is an identifier beginning or ending (but not both) with C<:>. A keyword can contain
letters (C<A-Za-z>), numbers (C<0-9>) and underscores (C<_>) just like identifiers in Perl. They
can additionally also contain hyphens (C<->) that will be converted to underscores.

A keyword is howver just a simple way to write a string. Here are some keywords and their
string equivalients:

    :foo        "foo"
    :foo-bar    "foo_bar"
    _foo23:     "_foo23"
    :-foo-      "_foo_"

The main advantage of keywords over strings is that they are easier to type and read. They are
especially useful for method calls and hash key lookups:

    (obj :foo-bar)      ; calls $obj->foo_bar

=head3 Barewords

!TAG<barewords>

A bareword is anything that didn't match any other token and that doesn't contain either kind
of cell (C<[]>, C<()> and C<{}>), any quotation character or string delimiter (C<'>, C<">, C<,> or C<`>),
an C<@> sign, a percent sign (C<%>), a semi-colon (C<;>) or a hashbang C<#>. Additionally, barewords
cannot start with a number. Here are some bareword examples:

    +
    foo/bar
    Foo::Bar
    baz23
    _
    λ

=head3 Booleans

!TAG<booleans>

Booleans begin with C<#>. They can be true (C<1>) or false (undefined). Besides the classical C<#t> for
true and C<#f> for false we also allow the following:

    #t          #f
    #yes        #no
    #true       #false

The alternatives can be more readable if you have to specify a lot of them.

=head2 Comments

There are two kinds of comments in C<Template::SX>. The first is a simple line based comment like in
Perl, except that the comment character is C<;>:

    (+ 2 3) ; (this will not be executed)

Another way to comment out pieces is a cell comment:

    (foo (# bar) baz)

The above is the same as

    (foo baz)

with the C<(# bar)> being removed because the cell began with C<#>.

=head2 Modules

!TAG<modules>
!TAG<importing>
!TAG<arguments>

You can turn a script into a module by using a C<module> declaration like this:

    (module (arguments required1 requires2 . optional1 optional2)
            (exports (some-group: foo bar) baz))

This has a few implications:

=over

=item * 

You can L<import|Template::SX::Library::Inserts/import> values that are exported
by a module. The C<exports> declaration has to be in the followinf format:

    (module (exports <spec> ...) ...)

where C<spec> is either a bareword or a group declaration. Groups look like this:

    (module (exports (groupname: foo bar baz) ...) ...)

This would declare the symbols C<foo>, C<bar> and C<baz> to be in the group
C<groupname>.

=item *

Your input arguments will now be validated. The format for the C<arguments> specification
is

    (module (arguments <required> ... . <optional> ...) ...)

This means that in the following line:

    (module (arguments foo bar . baz qux))

The values for C<foo> and C<bar> are required, while C<baz> and C<qux> are optional.

=back

=head2 Libraries

!TAG<libraries>

Most of the functionality that is not required across the board is put in libraries. All
libraries are organized under the default L<Template::SX::Library::Core> group.

=head2 Variables

!TAG<variables>

See L<Template::SX::Library::ScopeHandling> for information on how variables can be
declared and changed.

=end fusion






=head1 NAME

Template::SX - An S-Expression to Perl code inflator

=head1 SYNOPSIS

    my $sx  = Template::SX->new(use_global_cache => 1);
    my $res = $sx->run(file => $file, { somevalue => 23 });

=head1 INHERITANCE

=over 2

=item *

Template::SX

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<MooseX::Traits>

=back

=head1 DESCRIPTION

C<Template::SX> is an implementation for executing S-Expression code in Perl. The used language is
loosely based on Scheme, but many things are different to make it all more Perlish and easier to
use side-by-side with Perl.

=head2 A Summary

Because you might be to impatient to read all the documentation to find out if this does what you want,
here is a quick checklist:

=over

=item *

No tail-call-C<$anything>. While internally some places might use C<goto> to optimize for space or
speed, no user code will be implicitely tailcalled. 

=item *

Lisp and with this also Scheme are list-based languages. C<Template::SX> implements more of a data
structure language, in that it also allows you to create (and quote) Perl hashes.

=item *

It's slower than pure Perl, obviously.

=item *

Special handling for L<Moose type constraints|Moose::Manual::Types> to better integrate them into the
language. They can be imported, passed around as usual, used in function signatures, nested, etc.

=item *

Comes with a very simple REPL.

=item *

Lexically scoped and currently closing over environments, not value containers.

=item *

Includes a simple rendering system with L<Template::SX::Renderer::Plain> that allows specially formed
data structures to be compiled to HTML.

=item *

Can do Scheme style quoting (C<'>), quasiquoting (C<`>), unquoting (C<,>) and splicing unquotes (C<,@>).

=back

=head2 Why would you do something like that?

Basically, I wanted something like SXML in Perl. S-Expressions provide an extremely concise way of
building tree structures.

=head2 Compilation and Execution

It's a long way from a piece of string to running code. These are the steps that are currently made on
the way:

=over

=item *

First the body is turned into a L<stream|Template::SX::Reader::Stream> by the
L<reader|Template::SX::Reader>.

=item *

The reader will then create a new L<document|Template::SX::Document>. This new document receives the previously 
created stream and inflates itself into a tree structure.

=item *

To compile the tree structure, the document will create an L<inflator|Template::SX::Inflator>. The purpose of
the inflator is to provide an environment for the tree structure to be compiled in. The structure will be
recursively compiled to an inflation body consisting of Perl code that builds callbacks. This inflation body
is what should be cached on the filesystem if needed.

=item *

When the inflation body is evaluated, it will return an optimised tree of combined code references. The document
can then call this code reference (along with providing a suitable environment and user provided arguments) to
calculate the result.

=back

=head1 THE LANGUAGE

=head2 General Syntax

In general it all looks like Scheme. You call something by putting it in a list:

    (+ 2 3)         ; returns 5

Code can also be nested:

    (+ (* 2 2) 3)   ; returns 7

The evaluation order is left-to-right, inner-to-outer. Syntax elements might change
the order of argument evaluation or omit their evaluation at all:

    (if (get-something)
      (do-something) 
      (do-something-else))

In the above code C<do-something> will only be executed if C<get-something> returns
true. Otherwise C<do-<omsething-else> will be called.

For a non-syntax application, all elements of the application list are dynamic, including
the one at the operator position. This means that this will work as you expect:

    ((if (eq? do :add)
       +
       *)
     2 3)

For all intents and purposes, C<()> and C<[]> are synonymous. You can use C<[]>
instead to make parts stand out visually:

    (let [(x 3)
          (y 4)]
      (+ x y))

Unlike most other Lisps that I know of, you can also specify hashes in-line:

    { x: 4 y: 5 }

See L<Template::SX::Library::Quoting> for details on how to build complex inline data
structures.

=head2 Context

Every call in C<Template::SX> is made in scalar context. If you really have to call 
something in list context, see L<Template::SX::Library::Data::Functions/"apply/list">
for information.

=head2 Data Types

=head3 Numbers

Numbers are rather simple:

    (+ 3 -7 3.5 20_000 5.000_001 +7)

=head3 Strings

Strings can either be constant like this:

    "foo"

or contain runtime interpolations like this:

    "foo ${ (+ x y) } bar"

And, while it might screw up your string-highlighting, you can have strings in
interpolated strings too:

    "foo ${ (join ", " names) } bar"

=head3 Regular Expressions

Regular expressions have a slightly different syntax in L<Template::SX> than in raw
Perl. First, they start with C<rx>:

    rx/foo/i

The regular expression is I<always> in C<x> mode, which means you always have to
specify spaces explicitely. There is currently no direct interpolation in regular
expressions.

See L<Template::SX::Library::Data::Regex> for details about regular expression
handling.

=head3 Lists

Lists in a C<Template::SX> context refers to array references. Since there are no 
non-reference arrays in this system, and I didn't want to write "array reference" all
the time, I use both interchangably.

You can create lists with L<Template::SX::Library::Data::Lists/list> or by 
L<quoting|Template::SX::Library::Quoting> a C<()> or C<[]> structure.

=head3 Hashes

Hashes are always hash references. You can create them with
L<Template::SX::Library::Data::Hashes/hash> or with a (quoted or unquoted) C<{}> cell.

=head3 Objects

1TAG<object methods>

You can invoke objects just like functions. You have to pass the method to call in as
first argument. These will all call C<foo> on C<obj>:

    (obj :foo ...)
    (obj "foo" ...)
    (obj 'foo ...)

The following will call the method specified in C<bar>:

    (obj bar ...)

You can replace the C<...> with the arguments you want to pass to the method. Just like
in Perl, if the method argument is a code reference, it will be used instead of a method
lookup:

    (obj list)

will return a list containing the object, since L<list|Template::SX::Library::Data::Lists/list>
is a builtin function constructing lists.

B<Note> that L<Moose type constraints|Moose::Manual::Types> are not treated as objects. They are
handled specially so you can say things like:

    (HashRef Int)

See L<Template::SX::Library::Types> for more information.

=head3 Keywords

A keyword is an identifier beginning or ending (but not both) with C<:>. A keyword can contain
letters (C<A-Za-z>), numbers (C<0-9>) and underscores (C<_>) just like identifiers in Perl. They
can additionally also contain hyphens (C<->) that will be converted to underscores.

A keyword is howver just a simple way to write a string. Here are some keywords and their
string equivalients:

    :foo        "foo"
    :foo-bar    "foo_bar"
    _foo23:     "_foo23"
    :-foo-      "_foo_"

The main advantage of keywords over strings is that they are easier to type and read. They are
especially useful for method calls and hash key lookups:

    (obj :foo-bar)      ; calls $obj->foo_bar

=head3 Barewords

A bareword is anything that didn't match any other token and that doesn't contain either kind
of cell (C<[]>, C<()> and C<{}>), any quotation character or string delimiter (C<'>, C<">, C<,> or C<`>),
an C<@> sign, a percent sign (C<%>), a semi-colon (C<;>) or a hashbang C<#>. Additionally, barewords
cannot start with a number. Here are some bareword examples:

    +
    foo/bar
    Foo::Bar
    baz23
    _
    λ

=head3 Booleans

Booleans begin with C<#>. They can be true (C<1>) or false (undefined). Besides the classical C<#t> for
true and C<#f> for false we also allow the following:

    #t          #f
    #yes        #no
    #true       #false

The alternatives can be more readable if you have to specify a lot of them.

=head2 Comments

There are two kinds of comments in C<Template::SX>. The first is a simple line based comment like in
Perl, except that the comment character is C<;>:

    (+ 2 3) ; (this will not be executed)

Another way to comment out pieces is a cell comment:

    (foo (# bar) baz)

The above is the same as

    (foo baz)

with the C<(# bar)> being removed because the cell began with C<#>.

=head2 Modules

You can turn a script into a module by using a C<module> declaration like this:

    (module (arguments required1 requires2 . optional1 optional2)
            (exports (some-group: foo bar) baz))

This has a few implications:

=over

=item * 

You can L<import|Template::SX::Library::Inserts/import> values that are exported
by a module. The C<exports> declaration has to be in the followinf format:

    (module (exports <spec> ...) ...)

where C<spec> is either a bareword or a group declaration. Groups look like this:

    (module (exports (groupname: foo bar baz) ...) ...)

This would declare the symbols C<foo>, C<bar> and C<baz> to be in the group
C<groupname>.

=item *

Your input arguments will now be validated. The format for the C<arguments> specification
is

    (module (arguments <required> ... . <optional> ...) ...)

This means that in the following line:

    (module (arguments foo bar . baz qux))

The values for C<foo> and C<bar> are required, while C<baz> and C<qux> are optional.

=back

=head2 Libraries

Most of the functionality that is not required across the board is put in libraries. All
libraries are organized under the default L<Template::SX::Library::Core> group.

=head2 Variables

See L<Template::SX::Library::ScopeHandling> for information on how variables can be
declared and changed.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * default_libraries (optional)

Initial value for the L<default_libraries|/"default_libraries (required)"> attribute.

=item * document_traits (optional)

Initial value for the L<document_traits|/"document_traits (required)"> attribute.

=item * include_path (optional)

Initial value for the L<include_path|/"include_path (required)"> attribute.

=item * reader (optional)

Initial value for the L<reader|/"reader (required)"> attribute.

=item * use_global_cache (optional)

Initial value for the L<use_global_cache|/"use_global_cache (optional)"> attribute.

=back

=head2 all_function_names

    ->all_function_names()

=over

=back

Returns a list of all available functions in all libraries. This is mostly for easy
introspection like the REPL requires.

=head2 all_libraries

Delegation to a generated L<elements|Moose::Meta::Attribute::Native::MethodProvider::Array/elements> method for the L<default_libraries|/default_libraries (required)> attribute.

Returns all loaded libraries.

=head2 all_syntax_names

    ->all_syntax_names()

=over

=back

Returns a list of all syntax elements in all libraries. Mostly used for easy introspection
by the REPL.

=head2 clear_reader

Clearer for the L<reader|/"reader (required)"> attribute.

=head2 default_libraries

Reader for the L<default_libraries|/"default_libraries (required)"> attribute.

=head2 document_traits

Reader for the L<document_traits|/"document_traits (required)"> attribute.

=head2 has_reader

Predicate for the L<reader|/"reader (required)"> attribute.

=head2 include_path

Reader for the L<include_path|/"include_path (required)"> attribute.

=head2 read

    ->read(SourceType $type, Any $source, Str :$source_name)

=over

=item * Positional Parameters:

=over

=item * L<SourceType|Template::SX::Types/SourceType> C<$type>

How to treat the C<$source> argument.

=item * Any C<$source>

The source of the code to run.

=back

=item * Named Parameters:

=over

=item * Str C<:$source_name> (optional)

Name of the source, e.g. filename.

=back

=back

Reads a L<Template::SX::Document> from a C<$source> definition.

=head2 reader

Reader for the L<reader|/"reader (required)"> attribute.

=head2 run

    ->run(
        SourceType $type,
        Any $source,
        HashRef :$vars = {},
        Bool :$persist,
        Str :$source_name
    )

=over

=item * Positional Parameters:

=over

=item * L<SourceType|Template::SX::Types/SourceType> C<$type>

How to treat the C<$source> argument.

=item * Any C<$source>

The source of the code to run.

=back

=item * Named Parameters:

=over

=item * Bool C<:$persist> (optional)

If true, the passed in C<$vars> will not be copied but modified instead.

=item * Str C<:$source_name> (optional)

Name of the source, e.g. filename.

=item * HashRef C<:$vars> (optional)

Initial variables for the code.

=back

=back

L<Reads|/read> a document and runs it.

=head2 use_global_cache

Reader for the L<use_global_cache|/"use_global_cache (optional)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 default_libraries (required)

=over

=item * Type Constraint

L<LibraryList|Template::SX::Types/LibraryList>

=item * Default

Built during runtime.

=item * Constructor Argument

C<default_libraries>

=item * Associated Methods

L<default_libraries|/default_libraries>, L<all_libraries|/all_libraries>

=back

List of default library objects for new documents. Defaults to L<Template::SX::Library::Core>.

=head2 document_traits (required)

=over

=item * Type Constraint

ArrayRef[Str]

=item * Default

Built during runtime.

=item * Constructor Argument

C<document_traits>

=item * Associated Methods

L<document_traits|/document_traits>

=back

Traits that should be applied to new documents.

=head2 include_path (required)

=over

=item * Type Constraint

L<Dir|MooseX::Types::Path::Class/Dir>

=item * Default

Built during runtime.

=item * Constructor Argument

C<include_path>

=item * Associated Methods

L<include_path|/include_path>

=back

Where to look for other C<Template::SX> files to load.

=head2 reader (required)

=over

=item * Type Constraint

L<Template::SX::Reader>

=item * Default

Built lazily during runtime.

=item * Constructor Argument

C<reader>

=item * Associated Methods

L<reader|/reader>, L<has_reader|/has_reader>, L<clear_reader|/clear_reader>

=back

The reader object is used to translate code from text to a document.

=head2 use_global_cache (optional)

=over

=item * Type Constraint

Bool

=item * Constructor Argument

C<use_global_cache>

=item * Associated Methods

L<use_global_cache|/use_global_cache>

=back

If true, a process global storage for loaded documents will be used instead of recreating documents
each time. This can increase speeds drastically in long-running processes.

=head1 SEE ALSO

=over

=item * L<Template::SX::Library::Core>

=item * L<Template::SX::Renderer::Plain>

=back

=head1 AUTHORS

Robert 'phaylon' Sedlacek, C<rs@474.at>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 (c) Robert Sedlacek (phaylon)

This library is free software; you can redistribute it and/or modify it under the same terms
as Perl 5.10.0.

=cut