use MooseX::Declare;

role Language::SX::Renderer::TagBased::Trait::HTMLTidy {

    use HTML::Tidy ();
    use MooseX::Types::Moose qw( Object );

    has html_tidier => (
        isa         => 'HTML::Tidy',
        init_arg    => undef,
        lazy_build  => 1,
        handles     => {
            clean_html  => 'clean',
        },
    );

    method _build_html_tidier () {

        my $tidy = HTML::Tidy->new({
            output_html     => 1,
            indent          => 1,
            show_errors     => 0,
            show_warnings   => 0,
            tidy_mark       => 0,
            indent_cdata    => 1,
            input_encoding  => 'utf8',
        });

        return $tidy;
    }

    around render (@args) {

        my $html = $self->$orig(@args);

        return $self->clean_html($html);
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Renderer::Plain
@license  Language::SX

@role Language::SX::Renderer::TagBased::Trait::HTMLTidy
Tidy up HTML

=end fusion






=head1 NAME

Language::SX::Renderer::TagBased::Trait::HTMLTidy - Tidy up HTML

=head1 METHODS

=head2 meta

Returns the meta object for C<Language::SX::Renderer::TagBased::Trait::HTMLTidy> as an instance of L<Moose::Meta::Role>.

=head1 ATTRIBUTES

=head2 html_tidier (optional)

=over

=item * Type Constraint

L<HTML::Tidy>

=item * Default

Built lazily during runtime.

=item * Constructor Argument

This attribute can not be directly set at object construction.

=back

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Renderer::Plain>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut