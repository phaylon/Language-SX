use MooseX::Declare;

role Template::SX::Trait::CompileTidy {

    around compile_document (@args) {
        require Perl::Tidy;

        my $code = $self->$orig(@args);
        my $tidy;

        Perl::Tidy::perltidy(
            source      => \$code,
            destination => \$tidy,
            perltidyrc  => \q{
                -l=78
                -i=2
                -bar
                -nicp
                -nicb
            },
        );

        return $tidy;
    }
}
