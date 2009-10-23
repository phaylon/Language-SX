use MooseX::Declare;

class Template::SX::Inflator::Accessor is dirty {

    use MooseX::Types::Moose qw( CodeRef );

    clean;
    use overload '""' => 'as_string', fallback => 1;

    has get => (is => 'ro', isa => CodeRef, required => 1);
    has set => (is => 'ro', isa => CodeRef, required => 1);

    method render_getter { $self->get->() }
    method render_setter { $self->set->() }

    method as_string (Any @) { $self->render_getter }
}
