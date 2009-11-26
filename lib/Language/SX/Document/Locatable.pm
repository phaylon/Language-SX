use MooseX::Declare;

role Language::SX::Document::Locatable {

    use Language::SX::Types qw( Location );

    has location => (
        is          => 'rw',
        isa         => Location,
        required    => 1,
    );
};

1;

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@role Language::SX::Document::Locatable
Carry a location with an item

@attr location
The location meta information.

=end fusion






=head1 NAME

Language::SX::Document::Locatable - Carry a location with an item

=head1 METHODS

=head2 meta

Returns the meta object for C<Language::SX::Document::Locatable> as an instance of L<Moose::Meta::Role>.

=head1 ATTRIBUTES

=head2 location (required)

=over

=item * Type Constraint

L<Location|Language::SX::Types/Location>

=item * Constructor Argument

C<location>

=back

The location meta information.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut