use MooseX::Declare;

class Template::SX::Library::ScopeHandling::Lambda 
    with Template::SX::Document::Locatable {

    use MooseX::Types::Moose qw( ArrayRef Object ClassName );

    has body => (
        is          => 'ro',
        isa         => ArrayRef[Object],
        required    => 1,
    );

    has signature => (
        is          => 'ro',
        isa         => Object,
        required    => 1,
    );

    has library => (
        is          => 'ro',
        isa         => Object,
        required    => 1,
        handles     => {
            _render => '_render_lambda_from_signature',
        },
    );

    method compile (Object $inf, @) {

        return $self->_render($inf, $self->signature, $self->body);
    }
}
