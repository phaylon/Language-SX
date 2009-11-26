use MooseX::Declare;

class Language::SX::Document::Cell 
    extends Language::SX::Document::Container 
    with    Language::SX::Document::Locatable {

    use Language::SX::Constants qw( :all );
    use Language::SX::Types     qw( :all );
    use Data::Dump              qw( pp );

    my @Pairs     = qw/ ( ) [ ] { } /;
    my %OpenerFor = reverse @Pairs;
    my %CloserFor = @Pairs;
    my %Name      = qw/ ( normal ) normal [ square ] square { curly } curly /;

    Class::MOP::load_class($_)
        for E_SYNTAX, E_END_OF_STREAM;

    method compile (Language::SX::Inflator $inf, Scope $scope) {

        my $method = "compile_$scope";
        return $self->$method($inf);
    }

    method compile_functional { die "missing compile_functional implementation in subclass (@_)\n" }

    method _compile_structural_template (Language::SX::Inflator $inf, Object $item, CodeRef $collect) {

        if ($item->isa('Language::SX::Document::Cell::Application')) {

            if ($item->is_in_unquoting_state($inf) and (my $str = $item->is_unquote($inf))) {
                my ($identifier, @args) = $item->all_nodes;

                if (defined( my $syntax = $item->_try_compiling_as_syntax($inf, $identifier, \@args) )) {
                    return $collect->($syntax);
                }
                else {
                    E_INTERNAL->throw(
                        message     => "no syntax handler found for '$str' unquotes",
                        location    => $identifier->location,
                    );
                }
            }

            my @item_templates = map { $self->_compile_structural_template($inf, $_, $collect) } $item->all_nodes;
            return sprintf '[%s]', join ', ', @item_templates;
        }
        elsif ($item->isa('Language::SX::Document::Cell::Hash')) {

            my @item_templates = map { $self->_compile_structural_template($inf, $_, $collect) } $item->all_nodes;
            return sprintf '+{%s}', join ', ', @item_templates;
        }
        else {

            return $collect->($item);
        }
    }

    method compile_structural (Language::SX::Inflator $inf) {

        my @args;
        my $collector = sub {
            push @args, shift @_;
            return sprintf '@{ $_[%d] }', $#args;
        };

        my $template = sprintf(
            'sub { my @res = (%s); $res[0] }',
            $self->_compile_structural_template($inf, $self, $collector),
        );

        return $inf->render_call(
            method  => 'make_structure_builder',
            args    => {
                template    => $template,
                values      => sprintf(
                    '[%s]', join(
                        ', ',
                        map { blessed($_) ? $_->compile($inf, SCOPE_STRUCTURAL) : $_ } @args
                    ),
                ),
            },
        );
    }

    method _is_closing (Str $value) {
        return defined $OpenerFor{ $value };
    }

    method _closer_for (Str $value) {
        return $CloserFor{ $value };
    }

    method new_from_stream (
        ClassName $class: 
            Language::SX::Document          $doc, 
            Language::SX::Reader::Stream    $stream, 
            Str                             $value,
            Location                        $loc
    ) {
        
        my $self = $class->new_from_value($value, $loc);

        while (my $token = $stream->next_token) {
            my ($token_type, $token_value, $token_location) = @$token;

            if ($self->_is_closing($token->[1])) {

                if ($self->_closer_for($value) eq $token->[1]) {

                    if (my $head = $self->head_node) {

                        return undef
                            if $head->isa('Language::SX::Document::Bareword')
                                and $head->value eq '#';
                    }

                    return $self;
                }
                else {

                    E_SYNTAX->throw(
                        message  => sprintf(
                            q(expected cell to be closed with '%s' (%s), not '%s' (%s)), 
                            $CloserFor{ $value }, 
                            $Name{ $value },
                            $token->[1],
                            $Name{ $token->[1] },
                        ),
                        location => $token_location,
                    );
                }
            }

            my $node = $doc->new_node_from_stream($stream, $token);

            $self->add_node($node) 
                if defined $node;
        }

        E_END_OF_STREAM->throw(
            location => $loc,
            message  => 'unexpected end of stream before cell was closed',
        );
    }

    method new_from_value (ClassName $class: Str $value, Location $loc) {

        my $specific_class = $class->_find_class($value)
            or E_SYNTAX->throw(
                location    => $loc,
                message     => sprintf(q(invalid cell opener '%s'), $value),
            );

        Class::MOP::load_class($specific_class);
        return $specific_class->new(location => $loc);
    }

    method _find_class (ClassName $class: Str $value) {

        my $specific_class = (

              $value eq CELL_APPLICATION    ? 'Application'
            : $value eq CELL_ARRAY          ? 'Application'
            : $value eq CELL_HASH           ? 'Hash'
            : undef
        );

        return undef
            unless $specific_class;

        return join '::', __PACKAGE__, $specific_class;
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Cell::Application
@see_also Language::SX::Cell::Hash
@license  Language::SX

@class Language::SX::Document::Cell
Cell item base class

@method compile
Dispatches to either L</compile_functional> or L</compile_structural> depending
on C<$scope>.

@method compile_functional
This is a stub method that will die unless the subclass overrides it.

@method compile_structural
This method will compile the nodes as deep as possible into a structural template
and will pass it along with the compiled child nodes' values to 
L<Language::SX::Inflator/make_structure_builder>.

@method new_from_stream
%param $value Either C<(>, C<[> or C<{>. Used to determine the type of cell.
Will return a new cell subclass according to the C<$value>.

@method new_from_value
%param $value Same as in L</new_from_stream> with same function.
This method does the actual building of an empty cell subclass valid for the 
C<$value>.

@description
Holds the base functionality for all cell document item classes.

=end fusion






=head1 NAME

Language::SX::Document::Cell - Cell item base class

=head1 INHERITANCE

=over 2

=item *

Language::SX::Document::Cell

=over 2

=item *

L<Language::SX::Document::Container>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 APPLIED ROLES

=over

=item * L<Language::SX::Document::Locatable>

=back

=head1 DESCRIPTION

Holds the base functionality for all cell document item classes.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Language::SX::Document::Locatable/"location (required)"> attribute
composed in by L<Language::SX::Document::Locatable>.

=item * nodes (optional)

Initial value for the L<nodes|Language::SX::Document::Container/"nodes (required)"> attribute
inherited from L<Language::SX::Document::Container>.

=back

=head2 compile

    ->compile(Language::SX::Inflator $inf, Scope $scope)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=item * L<Scope|Language::SX::Types/Scope> C<$scope>

=back

=back

Dispatches to either L</compile_functional> or L</compile_structural> depending
on C<$scope>.

=head2 compile_functional

    ->compile_functional(@)

=over

=back

This is a stub method that will die unless the subclass overrides it.

=head2 compile_structural

    ->compile_structural(Language::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=back

=back

This method will compile the nodes as deep as possible into a structural template
and will pass it along with the compiled child nodes' values to 
L<Language::SX::Inflator/make_structure_builder>.

=head2 new_from_stream

    ->new_from_stream(
        ClassName $class:
        Language::SX::Document $doc,
        Language::SX::Reader::Stream $stream,
        Str $value,
        Location $loc
    )

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Document> C<$doc>

=item * L<Language::SX::Reader::Stream> C<$stream>

=item * Str C<$value>

Same as in L</new_from_stream> with same function.

=item * L<Location|Language::SX::Types/Location> C<$loc>

=back

=back

Will return a new cell subclass according to the C<$value>.

=head2 new_from_value

    ->new_from_value(ClassName $class: Str $value, Location $loc)

=over

=item * Positional Parameters:

=over

=item * Str C<$value>

Same as in L</new_from_stream> with same function.

=item * L<Location|Language::SX::Types/Location> C<$loc>

=back

=back

This method does the actual building of an empty cell subclass valid for the 
C<$value>.

=head2 meta

Returns the meta object for C<Language::SX::Document::Cell> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Cell::Application>

=item * L<Language::SX::Cell::Hash>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut