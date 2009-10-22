use MooseX::Declare;

role Template::SX::Document::Trait::CompileTidy {

    around compile (@args) {
        require Perl::Tidy;

        my $code = $self->$orig(@args);
        my $tidy;
        
        Perl::Tidy::perltidy(
            source      => \$code,
            destination => \$tidy,
            perltidyrc  => \q{
                -l=98
                -i=2
                -bar
                -nicp
                -nicb
            },
        );

        return $tidy;
    }
}