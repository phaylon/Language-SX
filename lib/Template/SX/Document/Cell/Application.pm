use MooseX::Declare;

class Template::SX::Document::Cell::Application 
    extends Template::SX::Document::Cell {

    use Data::Dump              qw( pp );
    use Perl6::Junction         qw( any );
    use Template::SX::Constants qw( :all );
    use Template::SX::Types;
    use Scalar::Util            qw( blessed );

    Class::MOP::load_class($_)
        for E_INTERNAL, E_SYNTAX;

    method _try_compiling_as_syntax (Object $inf, Object $node, ArrayRef[Object] $args) {

        return undef 
            unless $node->isa('Template::SX::Document::Bareword');

        return undef
            if $inf->known_lexical($node->value);

        if (my $syntax = $inf->find_library_syntax($node->value)) {
            return $inf->$syntax($self, @$args);
        }

        return undef;
    }

    method is_unquote (Template::SX::Inflator $inf) {

        return undef unless $self->node_count;
        my $node = $self->get_node(0);

        return undef
            unless $node->isa('Template::SX::Document::Bareword');

        return $node->value
            if $node->value eq any qw( unquote unquote-splicing );

        return undef;
    }

    method is_in_unquoting_state (Template::SX::Inflator $inf) {

        return undef
            if not $inf->quote_state 
               or $inf->quote_state ne QUOTE_QUASI
               or $self->node_count < 1;

        return 1;
    }

    method compile_functional (Template::SX::Inflator $inf) {

        unless ($self->node_count) {
            
            E_SYNTAX->throw(
                location    => $self->location,
                message     => q{empty application is illegal; use '() for empty list},
            );
        }

        my $apply = $self->head_node;
        my @args  = $self->tail_nodes;

        # syntax special case
        if (defined( my $syntax = $self->_try_compiling_as_syntax($inf, $apply, \@args) )) {
            return $syntax;
        }

        # normal application
        return $inf->render_call(
            method  => 'make_application',
            args    => {
                apply       => $apply->compile($inf, SCOPE_FUNCTIONAL),
                location    => pp($self->location),
                arguments   => sprintf(
                    '[%s]',
                    join(', ',
                        map {
                            $_->compile($inf, SCOPE_FUNCTIONAL);
                        } @args
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
@see_also Template::SX::Document::Cell::Hash
@see_also Template::SX::Inflator
@see_also Template::SX::Library::Quoting
@license  Template::SX

@class Template::SX::Document::Cell::Application
Function and syntax element application

@description
This item is responsible for applications of functions and syntax elements by usage
of C<( ... )> or C<[ ... ]> in the code.

@method compile_functional
Compiles to a call to L<Template::SX::Inflator/make_application> if there was no
syntax element found that could be used to compile this application.

@method is_in_unquoting_state
Determines if the application a valid quasiquote state exists that would allow unquoting.

@method is_unquote
Determines if the application is either an L<Template::SX::Library::Quoting/unquote> or
an L<Template::SX::Library::Quoting/unquote-splicing>.

=end fusion






=head1 NAME

Template::SX::Document::Cell::Application - Function and syntax element application

=head1 INHERITANCE

=over 2

=item *

Template::SX::Document::Cell::Application

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

This item is responsible for applications of functions and syntax elements by usage
of C<( ... )> or C<[ ... ]> in the code.

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

Compiles to a call to L<Template::SX::Inflator/make_application> if there was no
syntax element found that could be used to compile this application.

=head2 is_in_unquoting_state

    ->is_in_unquoting_state(Template::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=back

=back

Determines if the application a valid quasiquote state exists that would allow unquoting.

=head2 is_unquote

    ->is_unquote(Template::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=back

=back

Determines if the application is either an L<Template::SX::Library::Quoting/unquote> or
an L<Template::SX::Library::Quoting/unquote-splicing>.

=head2 meta

Returns the meta object for C<Template::SX::Document::Cell::Application> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Document::Cell::Hash>

=item * L<Template::SX::Inflator>

=item * L<Template::SX::Library::Quoting>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut