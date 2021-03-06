use MooseX::Declare;

class Language::SX::Document::Regex extends Language::SX::Document::Value {

    use Data::Dump              qw( pp );
    use Language::SX::Types     qw( :all );
    use Language::SX::Constants qw( :all );
    use MooseX::Types::Moose    qw( RegexpRef );

    has '+value' => (isa => RegexpRef);

    method compile (Language::SX::Inflator $inf, @) {

        return $inf->render_call(
            method  => 'make_regex_constant',
            args    => {
                value   => pp($self->value),
            },
        );
    }

    method new_from_stream (ClassName $class: Language::SX::Document $doc, Language::SX::Reader::Stream $stream, Str $value, Location $loc) {

        my $deparse = qr[
            \A rx . (.*) [\)\}/] ([a-z-]*) \Z
        ]xis;

        $value =~ $deparse
            or E_SYNTAX->throw(
                message     => 'invalid regular expression format',
                location    => $loc,
            );

        my ($contents, $modifiers) = ($1, lc $2);

        E_SYNTAX->throw(
            message     => "invalid modifier '$1' in regular expression",
            location    => $loc,
        ) if $modifiers =~ /([^msxi-])/;

        $contents =~ s/ (\$ | \@ | \%) /\\$1/gx;

        return $class->new(value => qr/(?${modifiers}:${contents})/x, location => $loc);
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Document::Regex
Regular expression value

@method compile
Compiles the regular expression into a call to L<Language::SX::Inflator/make_regex_constant>.

@method new_from_stream
%param $value String expression of the raw L<Language::SX> regular expression.
Creates a new regular expression value from a value.

@attr value
Same as L<Language::SX::Document::Value/value> except with a regular expression type constraint.

@description
This class renders regular expression values.

=end fusion






=head1 NAME

Language::SX::Document::Regex - Regular expression value

=head1 INHERITANCE

=over 2

=item *

Language::SX::Document::Regex

=over 2

=item *

L<Language::SX::Document::Value>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This class renders regular expression values.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Language::SX::Document::Value/"location (required)"> attribute
inherited from L<Language::SX::Document::Value>.

=item * value (B<required>)

Initial value for the L<value|/"value (required)"> attribute.

=back

=head2 compile

    ->compile(Language::SX::Inflator $inf, @)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=back

=back

Compiles the regular expression into a call to L<Language::SX::Inflator/make_regex_constant>.

=head2 new_from_stream

    ->new_from_stream(
        ClassName $class:
        Language::SX::Document $doc,
        Language::SX::Reader::Stream $stream,
        Str $value,
        Location $loc
    )

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Document> C<$doc>

=item * L<Language::SX::Reader::Stream> C<$stream>

=item * Str C<$value>

String expression of the raw L<Language::SX> regular expression.

=item * L<Location|Language::SX::Types/Location> C<$loc>

=back

=back

Creates a new regular expression value from a value.

=head2 value

Accessor for the L<value|/"value (required)"> attribute.

=head2 meta

Returns the meta object for C<Language::SX::Document::Regex> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 value (required)

=over

=item * Type Constraint

RegexpRef

=item * Constructor Argument

C<value>

=item * Associated Methods

L<value|/value>

=back

Same as L<Language::SX::Document::Value/value> except with a regular expression type constraint.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut