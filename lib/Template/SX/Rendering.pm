use MooseX::Declare;

role Template::SX::Rendering {
    with 'MooseX::Traits';

    requires qw( render_item );

    method render ($item) { $self->render_item($item) }
}
