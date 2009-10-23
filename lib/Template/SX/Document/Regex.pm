use MooseX::Declare;

class Template::SX::Document::Regex extends Template::SX::Document::Value {

    use Data::Dump              qw( pp );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use MooseX::Types::Moose    qw( RegexpRef );

    has '+value' => (isa => RegexpRef);

    method compile (Object $inf, @) {

        return $inf->render_call(
            method  => 'make_regex_constant',
            args    => {
                value   => pp($self->value),
            },
        );
    }

    method new_from_stream (ClassName $class: Object $doc, Object $stream, Str $value, Location $loc) {

        my $deparse = qr[
            \A rx . (.+) [\)\}/] ([a-z-]*) \Z
        ]xi;

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
