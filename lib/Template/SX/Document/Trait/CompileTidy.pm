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

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Document
@see_also Perl::Tidy
@license  Template::SX

@role Template::SX::Document::Trait::CompileTidy
Tidy up compiled Perl code for debugging

@description
This trait can be applied to L<Template::SX::Document> to tidy up the Perl code
generated to inflate the callback tree.

=end fusion






=head1 NAME

Template::SX::Document::Trait::CompileTidy - Tidy up compiled Perl code for debugging

=head1 DESCRIPTION

This trait can be applied to L<Template::SX::Document> to tidy up the Perl code
generated to inflate the callback tree.

=head1 METHODS

=head2 meta

Returns the meta object for C<Template::SX::Document::Trait::CompileTidy> as an instance of L<Moose::Meta::Role>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Document>

=item * L<Perl::Tidy>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut