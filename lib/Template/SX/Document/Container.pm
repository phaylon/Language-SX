use MooseX::Declare;

class Template::SX::Document::Container {
    
    use Template::SX::Types     qw( Scope );
    use MooseX::Types::Moose    qw( ArrayRef Object );

    has nodes => (
        traits      => [qw( Array )],
        isa         => ArrayRef[Object],
        required    => 1,
        default     => sub { [] },
        handles     => {
            all_nodes       => 'elements',
            add_node        => 'push',
            prepend_node    => 'unshift',
            map_nodes       => 'map',
            node_count      => 'count',
            get_node        => 'get',
            get_nodes       => 'splice',
        },
    );

    method head_node () {

        return undef unless $self->node_count;
        return $self->get_node(0);
    }

    method tail_nodes () {

        return () unless $self->node_count;
        return $self->get_nodes(1, $self->node_count - 1);
    }

    method compile_nodes (Template::SX::Inflator $inf, Scope $scope, Str $separator) {

        return join $separator, $self->map_nodes(sub {
            return $_->compile($inf, $scope);
        });
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Document
@see_also Template::SX::Document::Cell
@license  Template::SX

@class Template::SX::Document::Container
Document item container base class

@method compile_nodes
%param $separator Separator that will be used to join the compiled nodes together.
Compiles each child node in the specified C<$scope> and joins them together with
the C<$separator>.

@method head_node
Returns the first child node or an undefined value if no nodes are present.

@method tail_nodes
Returns a list containing all child nodes except the first.

@attr nodes
Contains the child nodes.

@description
This is a base class that is used by all document items that implement node container
functionality. This includes L<Template::SX::Document> itself.

=end fusion






=head1 NAME

Template::SX::Document::Container - Document item container base class

=head1 INHERITANCE

=over 2

=item *

Template::SX::Document::Container

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This is a base class that is used by all document items that implement node container
functionality. This includes L<Template::SX::Document> itself.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * nodes (optional)

Initial value for the L<nodes|/"nodes (required)"> attribute.

=back

=head2 add_node

Delegation to a generated L<push|Moose::Meta::Attribute::Native::MethodProvider::Array/push> method for the L<nodes|/nodes (required)> attribute.

=head2 all_nodes

Delegation to a generated L<elements|Moose::Meta::Attribute::Native::MethodProvider::Array/elements> method for the L<nodes|/nodes (required)> attribute.

=head2 compile_nodes

    ->compile_nodes(
        Template::SX::Inflator $inf,
        Scope $scope,
        Str $separator
    )

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=item * L<Scope|Template::SX::Types/Scope> C<$scope>

=item * Str C<$separator>

Separator that will be used to join the compiled nodes together.

=back

=back

Compiles each child node in the specified C<$scope> and joins them together with
the C<$separator>.

=head2 get_node

Delegation to a generated L<get|Moose::Meta::Attribute::Native::MethodProvider::Array/get> method for the L<nodes|/nodes (required)> attribute.

=head2 get_nodes

Delegation to a generated L<splice|Moose::Meta::Attribute::Native::MethodProvider::Array/splice> method for the L<nodes|/nodes (required)> attribute.

=head2 head_node

    ->head_node()

=over

=back

Returns the first child node or an undefined value if no nodes are present.

=head2 map_nodes

Delegation to a generated L<map|Moose::Meta::Attribute::Native::MethodProvider::Array/map> method for the L<nodes|/nodes (required)> attribute.

=head2 node_count

Delegation to a generated L<count|Moose::Meta::Attribute::Native::MethodProvider::Array/count> method for the L<nodes|/nodes (required)> attribute.

=head2 prepend_node

Delegation to a generated L<unshift|Moose::Meta::Attribute::Native::MethodProvider::Array/unshift> method for the L<nodes|/nodes (required)> attribute.

=head2 tail_nodes

    ->tail_nodes()

=over

=back

Returns a list containing all child nodes except the first.

=head2 meta

Returns the meta object for C<Template::SX::Document::Container> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 nodes (required)

=over

=item * Type Constraint

ArrayRef[Object]

=item * Default

Built during runtime.

=item * Constructor Argument

C<nodes>

=item * Associated Methods

L<add_node|/add_node>, L<get_node|/get_node>, L<map_nodes|/map_nodes>, L<get_nodes|/get_nodes>, L<node_count|/node_count>, L<prepend_node|/prepend_node>, L<all_nodes|/all_nodes>

=back

Contains the child nodes.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Document>

=item * L<Template::SX::Document::Cell>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut