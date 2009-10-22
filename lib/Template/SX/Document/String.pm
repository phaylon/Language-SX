use MooseX::Declare;

class Template::SX::Document::String {

    use String::Escape          qw( unprintable );
    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( Str ArrayRef Object );

    Class::MOP::load_class($_)
        for E_SYNTAX, E_INTERNAL, 'Template::SX::Document::String::Constant';

    has string_parts => (
        traits      => [qw( Array )],
        isa         => ArrayRef[Object | ArrayRef[Object]],
        required    => 1,
        handles     => {
            all_string_parts    => 'elements',
            string_part_count   => 'count',
        },
    );

    method compile (Object $inf, Scope $scope) {

        return $inf->render_call(
            method  => 'make_concatenation',
            args    => {
                elements => $self->render_elements($inf, $scope),
            },
        );
    }

    method render_elements (Object $inf, Scope $scope) {

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

    method new_from_stream (ClassName $class: Object $doc, Object $stream, Str $value, Location $loc) {

        my $skipped = 0;
        $value = $stream->content_substr($loc->{offset});

        $value =~ s/\A"//
            or E_INTERNAL->throw(
                message     => "invalid string format: $value",
                location    => $loc,
            );

        $skipped++;
        my @parts;

        while (length $value) {

            if ($value =~ s/\A (.*?) ( \$ | (?: (?<! \\ ) " ) ) //x) {
                my ($const, $end) = ($1, $2);

                push @parts, Template::SX::Document::String::Constant->new(
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


