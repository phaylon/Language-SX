use MooseX::Declare;

role Template::SX::Document::Locatable {

    use Template::SX::Types qw( Location );

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

@see_also Template::SX
@license  Template::SX

@role Template::SX::Document::Locatable
Carry a location with an item

@attr location
The location meta information.

=end fusion






=head1 NAME

Template::SX::Document::Locatable - Carry a location with an item

=head1 METHODS

=head2 meta

Returns the meta object for C<Template::SX::Document::Locatable> as an instance of L<Moose::Meta::Role>.

=head1 ATTRIBUTES

=head2 location (required)

=over

=item * Type Constraint

L<Location|Template::SX::Types/Location>

=item * Constructor Argument

C<location>

=back

The location meta information.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut