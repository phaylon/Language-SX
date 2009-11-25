use MooseX::Declare;

role Template::SX::Rendering {
    with 'MooseX::Traits';

    requires qw( render_item );

    method render ($tree) { $self->render_item($tree) }
}

1;

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Renderer::TagBased
@see_also Template::SX::Renderer::Plain
@license  Template::SX

@role Template::SX::Rendering
Role for rendering tree transformers

@requires render_item
Called to render a single tree node.

@method render
%param $tree The tree to render.
Takes a tree structure and renders it.

@DESCRIPTION
This role is applied to all rendering tree transformers to guarantee a compatible
entry point for views and such.

=end fusion






=head1 NAME

Template::SX::Rendering - Role for rendering tree transformers

=head1 REQUIRED METHODS

=head2 render_item

Called to render a single tree node.

=head1 APPLIED ROLES

=over

=item * L<MooseX::Traits>

=back

=head1 DESCRIPTION

This role is applied to all rendering tree transformers to guarantee a compatible
entry point for views and such.

=head1 METHODS

=head2 render

    ->render($tree)

=over

=item * Positional Parameters:

=over

=item * C<$tree>

The tree to render.

=back

=back

Takes a tree structure and renders it.

=head2 meta

Returns the meta object for C<Template::SX::Rendering> as an instance of L<Moose::Meta::Role>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Renderer::TagBased>

=item * L<Template::SX::Renderer::Plain>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut