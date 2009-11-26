use MooseX::Declare;
use utf8;

class Language::SX::Document::String {

    use String::Escape          qw( unprintable );
    use Scalar::Util            qw( blessed );
    use Language::SX::Constants qw( :all );
    use Language::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( Str ArrayRef Object );

    Class::MOP::load_class($_)
        for E_SYNTAX, E_INTERNAL, 'Language::SX::Document::String::Constant';

    has string_parts => (
        traits      => [qw( Array )],
        isa         => ArrayRef['Language::SX::Document::String::Constant' | ArrayRef[Object]],
        required    => 1,
        handles     => {
            all_string_parts    => 'elements',
            string_part_count   => 'count',
        },
    );

    method compile (Language::SX::Inflator $inf, Scope $scope) {

        return $inf->render_call(
            method  => 'make_concatenation',
            args    => {
                elements => $self->render_elements($inf, $scope),
            },
        );
    }

    method render_elements (Language::SX::Inflator $inf, Scope $scope) {

        return sprintf(
            '[%s]', join(
                ', ',
                map {
                    is_ArrayRef($_)
                    ? $inf->render_sequence($_)
                    : $_->compile($inf, SCOPE_FUNCTIONAL)
                } $self->all_string_parts,
            ),
        );
    }

    method new_from_stream (ClassName $class: Language::SX::Document $doc, Language::SX::Reader::Stream $stream, Str $value, Location $loc) {

        my $skipped = 0;
        $value = $stream->content_substr($loc->{offset});

        $value =~ s/\A ( " | » ) //x
            or E_INTERNAL->throw(
                message     => "invalid string format: $value",
                location    => $loc,
            );

        my $end_mark = $1 eq '"' ? '"' : '«';

        $skipped++;
        my @parts;

        while (length $value) {

            if ($value =~ s/\A (.*?) ( \$ | (?: (?<! \\ ) $end_mark ) ) //xs) {
                my ($const, $end) = ($1, $2);

                push @parts, Language::SX::Document::String::Constant->new(
                    value       => unprintable($const),
                    location    => $stream->substream(offset => $loc->{offset} + $skipped)->current_location,
                );

                $skipped += length($const) + 1;

                if ($end eq '$') {

                    if ($value =~ /\A \{/x) {

                        my $old_offset  = $loc->{offset} + $skipped;
                        my $substream   = $stream->substream(offset => $old_offset);
                        my $token       = $substream->next_token;
                        my $node        = $doc->new_node_from_stream($substream, $token);
                        my $new_offset  = $substream->offset;
                        my $removed     = $new_offset - $old_offset;

                        $skipped += $removed;
                        substr($value, 0, $removed) = '';

                        push @parts, [$node->all_nodes];
                    }
                    else {

                        E_SYNTAX->throw(
                            message     => q(expected '{ ... }' for interpolation after '$'),
                            location    => $stream->substream(offset => $loc->{offset} + $skipped)->current_location,
                        );
                    }
                }
                else {

                    $stream->offset($loc->{offset} + $skipped);

                    if ($end_mark ne '"') {

                        $parts[0]->clean_front;

                        $_->clean_lines for grep { blessed $_ } @parts;

                        $parts[-1]->clean_end;
                    }

                    if (@parts == 1) {
                        return $parts[0];
                    }

                    return $class->new(string_parts => \@parts);
                }
            }
            else {

                E_SYNTAX->throw(
                    message     => 'missing end of string, maybe runaway',
                    location    => $loc,
                );
            }
        }
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Document::String::Constant
@license  Language::SX

@class Language::SX::Document::String
Interpolated and constant string values

@method compile
Compiles the string into a call to L<Language::SX::Inflator/make_concatenation> that that
will build a single string with the values rendered by L</render_elements>.

@method new_from_stream
%param $value Either C<"> or C<»> designating a string start.
Parses a string in the stream into a tree structure containing constant strings and
interpolated parts as L</"string_parts (required)">.

@method render_elements
This will render L</all_string_parts> in a functional scope. Interpolated values will be
rendered by L<Language::SX::Inflator/render_sequence>.

@attr string_parts
A list of mixed string constants and array reference sequences forming the contents of
the string.

@description
This class handles constant and interpolating strings and their transformations.

=end fusion






=head1 NAME

Language::SX::Document::String - Interpolated and constant string values

=head1 INHERITANCE

=over 2

=item *

Language::SX::Document::String

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This class handles constant and interpolating strings and their transformations.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * string_parts (B<required>)

Initial value for the L<string_parts|/"string_parts (required)"> attribute.

=back

=head2 all_string_parts

Delegation to a generated L<elements|Moose::Meta::Attribute::Native::MethodProvider::Array/elements> method for the L<string_parts|/string_parts (required)> attribute.

=head2 compile

    ->compile(Language::SX::Inflator $inf, Scope $scope)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=item * L<Scope|Language::SX::Types/Scope> C<$scope>

=back

=back

Compiles the string into a call to L<Language::SX::Inflator/make_concatenation> that that
will build a single string with the values rendered by L</render_elements>.

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

Either C<"> or C<»> designating a string start.

=item * L<Location|Language::SX::Types/Location> C<$loc>

=back

=back

Parses a string in the stream into a tree structure containing constant strings and
interpolated parts as L</"string_parts (required)">.

=head2 render_elements

    ->render_elements(Language::SX::Inflator $inf, Scope $scope)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=item * L<Scope|Language::SX::Types/Scope> C<$scope>

=back

=back

This will render L</all_string_parts> in a functional scope. Interpolated values will be
rendered by L<Language::SX::Inflator/render_sequence>.

=head2 string_part_count

Delegation to a generated L<count|Moose::Meta::Attribute::Native::MethodProvider::Array/count> method for the L<string_parts|/string_parts (required)> attribute.

=head2 meta

Returns the meta object for C<Language::SX::Document::String> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 string_parts (required)

=over

=item * Type Constraint

ArrayRef[ArrayRef[Object]|L<Language::SX::Document::String::Constant>]

=item * Constructor Argument

C<string_parts>

=item * Associated Methods

L<string_part_count|/string_part_count>, L<all_string_parts|/all_string_parts>

=back

A list of mixed string constants and array reference sequences forming the contents of
the string.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Document::String::Constant>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut