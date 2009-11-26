use MooseX::Declare;

class Language::SX::Document::Cell::Hash
    extends Language::SX::Document::Cell {

    use Language::SX::Constants qw( :all );
    use Language::SX::Types     qw( :all );

    Class::MOP::load_class($_)
        for E_SYNTAX;

    method compile_functional (Language::SX::Inflator $inf) {
        
        E_SYNTAX->throw(
            message     => 'hash creation in functional mode requires even number of items',
            location    => $self->location,
        ) if $self->node_count % 2;

        return $inf->render_call(
            method  => 'make_hash_builder',
            args    => {
                items => sprintf(
                    '[%s]', join(
                        ', ',
                        map { $_->compile($inf, SCOPE_FUNCTIONAL) } $self->all_nodes,
                    ),
                ),
            },
        );
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Document::Cell::Application
@see_also Language::SX::Inflator
@see_also Language::SX::Library::Quoting
@license  Language::SX

@class Language::SX::Document::Cell::Hash
Inline hashes

@method compile_functional
This method compiles the item to a call to L<Language::SX::Inflator/make_hash_builder>.
A hash reference will be created inline while all elements of the cell will be compiled
functionally.

@description
This item represents an inline specification of a hash via C<{ ... }>.

=end fusion






=head1 NAME

Language::SX::Document::Cell::Hash - Inline hashes

=head1 INHERITANCE

=over 2

=item *

Language::SX::Document::Cell::Hash

=over 2

=item *

L<Language::SX::Document::Cell>

=over 2

=item *

L<Language::SX::Document::Container>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=back

=head1 DESCRIPTION

This item represents an inline specification of a hash via C<{ ... }>.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Language::SX::Document::Cell/"location (required)"> attribute
inherited from L<Language::SX::Document::Cell>.

=item * nodes (optional)

Initial value for the L<nodes|Language::SX::Document::Container/"nodes (required)"> attribute
inherited from L<Language::SX::Document::Container>.

=back

=head2 compile_functional

    ->compile_functional(Language::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=back

=back

This method compiles the item to a call to L<Language::SX::Inflator/make_hash_builder>.
A hash reference will be created inline while all elements of the cell will be compiled
functionally.

=head2 meta

Returns the meta object for C<Language::SX::Document::Cell::Hash> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Document::Cell::Application>

=item * L<Language::SX::Inflator>

=item * L<Language::SX::Library::Quoting>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut