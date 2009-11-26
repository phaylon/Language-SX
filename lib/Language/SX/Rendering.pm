use MooseX::Declare;

role Language::SX::Rendering {
    with 'MooseX::Traits';

    requires qw( render_item );

    sub render { $_[0]->render_item($_[1]) }

 #   method render ($tree) { $self->render_item($tree) }
}

1;

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Renderer::TagBased
@see_also Language::SX::Renderer::Plain
@license  Language::SX

@role Language::SX::Rendering
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

Language::SX::Rendering - Role for rendering tree transformers

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

Takes a tree structure and renders it.

=head2 meta

Returns the meta object for C<Language::SX::Rendering> as an instance of L<Moose::Meta::Role>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Renderer::TagBased>

=item * L<Language::SX::Renderer::Plain>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut