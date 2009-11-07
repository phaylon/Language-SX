use MooseX::Declare;

role Template::SX::Renderer::TagBased::Trait::HTMLTidy {

    use HTML::Tidy qw( TIDY_WARNING TIDY_ERROR );
    use MooseX::Types::Moose qw( Object );

    has html_tidier => (
        isa         => Object,
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
