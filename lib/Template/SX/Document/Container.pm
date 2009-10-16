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

    method head_node {

        return undef unless $self->node_count;
        return $self->get_node(0);
    }

    method tail_nodes {

        return () unless $self->node_count;
        return $self->get_nodes(1, $self->node_count - 1);
    }

    method compile_nodes (Object $inf, Scope $scope, Str $separator) {

        return join $separator, $self->map_nodes(sub {
            return $_->compile($inf, $scope);
        });
    }
}
