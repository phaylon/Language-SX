use MooseX::Declare;

class Language::SX::Library::Quoting extends Language::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Data::Dump              qw( pp );
    use Language::SX::Types     qw( :all );
    use Language::SX::Constants qw( :all );
    Class::MOP::load_class($_)
        for E_SYNTAX, E_TYPE;
    
    class_has '+function_map';
    class_has '+syntax_map';

    method additional_inflator_traits {
        'QuoteState';
    }

    CLASS->add_syntax(quote => sub {
        my $self = shift;
        return $self->_quote(QUOTE_FULL, @_);
    });

    CLASS->add_syntax(quasiquote => sub {
        my $self = shift;
        return $self->_quote(QUOTE_QUASI, @_);
    });

    CLASS->add_syntax(unquote => sub {
        my $self = shift;
        return $self->_unquote(@_);
    });

    CLASS->add_syntax('unquote-splicing' => sub {
        my $self = shift;
        my ($inf, $cell, $item) = @_;

        my $unquoted = $self->_unquote(@_);

        return $inf->render_call(
            library     => $CLASS,
            method      => 'make_unquote_splicer',
            args        => {
                splice      => $unquoted,
                location    => pp($item->location),
            },
        );
    });

    method make_unquote_splicer (CodeRef :$splice!, Location :$location!) {
        
        return sub {
            my $env = shift;
            my $val = $splice->($env);

            E_TYPE->throw(message => 'spliced element is not an array reference', location => $location)
                unless ref $val eq 'ARRAY';

            return @$val;
        };
    }

    method _unquote (Object $inf, Object $cell, @args) {

        E_SYNTAX->throw(message => 'only single item can be unquoted at a time', location => $cell->location)
            unless @args == 1;

        E_SYNTAX->throw(message => 'illegal unquote outside of quasi-quoted environment', location => $cell->location)
            unless $inf->quote_state;

        my $unquoted = $args[0];

        return $unquoted->compile($inf, SCOPE_STRUCTURAL)
            unless $inf->quote_state eq QUOTE_QUASI;

        my $new_inf = $inf->clone_without_quote_state;
        return $unquoted->compile($new_inf, SCOPE_FUNCTIONAL);
    }

    method _quote (QuoteState $state, Object $inf, Object $cell, @args) {

#        warn "QUOTING " . pp([ map "$_", $cell->all_nodes ]);

        E_SYNTAX->throw(message => 'only single item can be quoted at a time', location => $cell->location)
            unless @args == 1;

        my $quoted = $args[0];

        if ($state eq QUOTE_QUASI and $quoted->isa('Language::SX::Document::Cell::Application')) {

            if (my $unquote = $quoted->is_unquote($inf)) {

                E_SYNTAX->throw(
                    message     => 'unquote-splicing directly inside quasiquote is illegal',
                    location    => $quoted->location,
                ) if $unquote eq 'unquote-splicing';
            }
        }

        my $new_inf = $inf->clone_with_quote_state($state);
        return $quoted->compile($new_inf, SCOPE_STRUCTURAL);
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Library::Quoting
All functionality related to quoting

@method additional_inflator_traits
Returns C<QuoteState>.

@method make_unquote_splicer
Builds a callback that will evaluate an expression in list context and return
the items as multiple values so it can be interpolated by a structural template.

@SYNOPSIS

    ; simple deep quote
    '(1 2 (foo bar { x: 3 }) 5)

    ; quasiquote
    `(1 2 (foo) 3)

    ; quasiquote with unquote and unquote-splicing
    ; result is (1 2 (23 24 25) 4 23 24 25 5)
    (define foo '(23 24 25))
    `(1 2 ,foo 4 ,@foo 5)

@DESCRIPTION
This library contains all necessary functionality to allow quoting of data. This
is a easy and expressive way of building data structures.

The class L<Language::SX::Document::Quote> is handling the transformation of the
special syntax elements into normal applications. These will then be handled by
the syntax elements in this library. The mapping is:

!TAG<quoting>

=over

=item * C<'>

    '<item>

A normal single quote is the same as an invocation of L</quote>:

    (quote <item>)

=item * C<`>

    `<item>

A quotation with a grave accent character is the same as an invocation of L</quasiquote>:

    (quasiquote <item>)

=item * C<,>

    ,<item>

A comma is the same as an invocation of L</unquote>:

    (unquote <item>)

=item * C<,@>

    ,@<item>

A comma followed by an C<@> sign is the same as an invocation of L</unquote-splicing>:

    (unquote-splicing <item>)

=back

=head2 A note about quoted items

!TAG<lists>

Since normal cells that are flanked by C<()> and C<[]> will evaluate their contents in a
functional context, you have to quote them to get a list reference:

    `(1 2 ,foo 3)

The above inserts the value of C<foo> at the third index of the list. Hashes are however
not used for anything besides hash creation. This means that you can use the following
in any context and can expect to receive a hash reference (An exception are syntax elements
that can influence their arguments compilation and the final outcome):

    { foo: 23 }

has exactly the same effect as

    '{ foo: 23 }

The big difference is that while the elements in the second example are quoted too, the
ones in the first aren't. So this:

    (let ((x :foo) (y 3))
      { x y })              ; returns { foo => 3 }

will evaluate C<x> as key and C<y> as value, while this

    (let ((x :foo) (y 3))
      '{ x y })             ; returns { x => RuntimeBareword('y') }

will have a stringified version of the first item as key (because hash keys in Perl are
stringified) and the value will be an L<Language::SX::Runtime::Bareword>.

So to build a hash with a couple of dynamic keys and values from a list you'd have to
L</quasiquote> it:

    `{ ,@list-of-things 
       ,@other-list-of-things 
       other-key: ,other-value }

=head1 PROVIDED SYNTAX ELEMENTS

All these syntax elements take exactly one argument.

=head2 quote

    (quote <item>)
    '<item>

This will quote its argument fully, without regard for any specifications of L</unquote> or
L</unquote-splicing>.

=head2 quasiquote

    (quasiquote <item>)
    `<item>

Same as L</quote> but it allows parts of the data structure to be inserted dynamically with
L</unquote> or L</unquote-splicing>.

=head2 unquote

    (unquote <item>)
    ,<item>

This syntax element can only be used inside a L</quasiquote> context. It will evaluate the
argument and insert the return value into its place in the data structure:

    (quasiquote 1 2 (unquote (+ 3 4)) 5)
    `(1 2 ,(+ 3 4) 5)
                        ; => (1 2 7 5)

=head2 unquote-splicing

    (unquote-splicing <item>)
    ,@<item>

The same as L</unquote> but expects the expression to return an array reference. The contents
will then be inserted flattened into its place in the data structure:

    (quasiquote (1 2 (unquote (list 3 4 5)) 6))
    `(1 2 ,@(list 3 4 5) 6)
                        ; => (1 2 3 4 5 6)

=end fusion






=head1 NAME

Language::SX::Library::Quoting - All functionality related to quoting

=head1 SYNOPSIS

    ; simple deep quote
    '(1 2 (foo bar { x: 3 }) 5)

    ; quasiquote
    `(1 2 (foo) 3)

    ; quasiquote with unquote and unquote-splicing
    ; result is (1 2 (23 24 25) 4 23 24 25 5)
    (define foo '(23 24 25))
    `(1 2 ,foo 4 ,@foo 5)

=head1 INHERITANCE

=over 2

=item *

Language::SX::Library::Quoting

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

This library contains all necessary functionality to allow quoting of data. This
is a easy and expressive way of building data structures.

The class L<Language::SX::Document::Quote> is handling the transformation of the
special syntax elements into normal applications. These will then be handled by
the syntax elements in this library. The mapping is:

=over

=item * C<'>

    '<item>

A normal single quote is the same as an invocation of L</quote>:

    (quote <item>)

=item * C<`>

    `<item>

A quotation with a grave accent character is the same as an invocation of L</quasiquote>:

    (quasiquote <item>)

=item * C<,>

    ,<item>

A comma is the same as an invocation of L</unquote>:

    (unquote <item>)

=item * C<,@>

    ,@<item>

A comma followed by an C<@> sign is the same as an invocation of L</unquote-splicing>:

    (unquote-splicing <item>)

=back

=head2 A note about quoted items

Since normal cells that are flanked by C<()> and C<[]> will evaluate their contents in a
functional context, you have to quote them to get a list reference:

    `(1 2 ,foo 3)

The above inserts the value of C<foo> at the third index of the list. Hashes are however
not used for anything besides hash creation. This means that you can use the following
in any context and can expect to receive a hash reference (An exception are syntax elements
that can influence their arguments compilation and the final outcome):

    { foo: 23 }

has exactly the same effect as

    '{ foo: 23 }

The big difference is that while the elements in the second example are quoted too, the
ones in the first aren't. So this:

    (let ((x :foo) (y 3))
      { x y })              ; returns { foo => 3 }

will evaluate C<x> as key and C<y> as value, while this

    (let ((x :foo) (y 3))
      '{ x y })             ; returns { x => RuntimeBareword('y') }

will have a stringified version of the first item as key (because hash keys in Perl are
stringified) and the value will be an L<Language::SX::Runtime::Bareword>.

So to build a hash with a couple of dynamic keys and values from a list you'd have to
L</quasiquote> it:

    `{ ,@list-of-things 
       ,@other-list-of-things 
       other-key: ,other-value }

=head1 PROVIDED SYNTAX ELEMENTS

All these syntax elements take exactly one argument.

=head2 quote

    (quote <item>)
    '<item>

This will quote its argument fully, without regard for any specifications of L</unquote> or
L</unquote-splicing>.

=head2 quasiquote

    (quasiquote <item>)
    `<item>

Same as L</quote> but it allows parts of the data structure to be inserted dynamically with
L</unquote> or L</unquote-splicing>.

=head2 unquote

    (unquote <item>)
    ,<item>

This syntax element can only be used inside a L</quasiquote> context. It will evaluate the
argument and insert the return value into its place in the data structure:

    (quasiquote 1 2 (unquote (+ 3 4)) 5)
    `(1 2 ,(+ 3 4) 5)
                        ; => (1 2 7 5)

=head2 unquote-splicing

    (unquote-splicing <item>)
    ,@<item>

The same as L</unquote> but expects the expression to return an array reference. The contents
will then be inserted flattened into its place in the data structure:

    (quasiquote (1 2 (unquote (list 3 4 5)) 6))
    `(1 2 ,@(list 3 4 5) 6)
                        ; => (1 2 3 4 5 6)

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 additional_inflator_traits

    ->additional_inflator_traits(@)

=over

=back

Returns C<QuoteState>.

=head2 make_unquote_splicer

    ->make_unquote_splicer(CodeRef :$splice!, Location :$location!)

=over

=item * Named Parameters:

=over

=item * L<Location|Language::SX::Types/Location> C<:$location>

=item * CodeRef C<:$splice>

=back

=back

Builds a callback that will evaluate an expression in list context and return
the items as multiple values so it can be interpolated by a structural template.

=head2 meta

Returns the meta object for C<Language::SX::Library::Quoting> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut