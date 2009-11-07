use MooseX::Declare;

class Template::SX::Inflator::EscapeScope {

    use MooseX::Types::Moose qw( Int Bool );

    has was_accessed => (
        is          => 'ro',
        writer      => '_set_was_accessed',
        isa         => Bool,
    );

    # TODO add options for return, goto and redo
    method render_exit (Object $inf) {

        $self->_set_was_accessed(1);
        return $inf->render_call(
            method  => 'make_escape_scope_exit',
            args    => {},
        );
    }

    method wrap (Object $inf, Str $body) {

        return $body unless $self->was_accessed;

        return $inf->render_call(
            method  => 'make_escape_scope',
            args    => {
                scope   => $body,
            },
        );
    }
}
