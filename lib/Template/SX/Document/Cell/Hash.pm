use MooseX::Declare;

class Template::SX::Document::Cell::Hash
    extends Template::SX::Document::Cell {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );

    Class::MOP::load_class($_)
        for E_SYNTAX;

    method compile_functional (Template::SX::Inflator $inf) {
        
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

@see_also Template::SX
@see_also Template::SX::Document::Cell::Application
@see_also Template::SX::Inflator
@see_also Template::SX::Library::Quoting
@license  Template::SX

@class Template::SX::Document::Cell::Hash
Inline hashes

@method compile_functional
This method compiles the item to a call to L<Template::SX::Inflator/make_hash_builder>.
A hash reference will be created inline while all elements of the cell will be compiled
functionally.

@description
This item represents an inline specification of a hash via C<{ ... }>.

=end fusion






=head1 NAME

Template::SX::Document::Cell::Hash - Inline hashes

=head1 INHERITANCE

=over 2

=item *

Template::SX::Document::Cell::Hash

=over 2

=item *

L<Template::SX::Document::Cell>

=over 2

=item *

L<Template::SX::Document::Container>

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

Initial value for the L<location|Template::SX::Document::Cell/"location (required)"> attribute
inherited from L<Template::SX::Document::Cell>.

=item * nodes (optional)

Initial value for the L<nodes|Template::SX::Document::Container/"nodes (required)"> attribute
inherited from L<Template::SX::Document::Container>.

=back

=head2 compile_functional

    ->compile_functional(Template::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=back

=back

This method compiles the item to a call to L<Template::SX::Inflator/make_hash_builder>.
A hash reference will be created inline while all elements of the cell will be compiled
functionally.

=head2 meta

Returns the meta object for C<Template::SX::Document::Cell::Hash> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Document::Cell::Application>

=item * L<Template::SX::Inflator>

=item * L<Template::SX::Library::Quoting>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut