use MooseX::Declare;

class Template::SX::Document::Cell 
    extends Template::SX::Document::Container 
    with    Template::SX::Document::Locatable {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );
    use Data::Dump              qw( pp );

    my @Pairs     = qw/ ( ) [ ] { } /;
    my %OpenerFor = reverse @Pairs;
    my %CloserFor = @Pairs;
    my %Name      = qw/ ( normal ) normal [ square ] square { curly } curly /;

    Class::MOP::load_class(E_SYNTAX);

    method compile (Object $inf, Scope $scope) {

        my $method = "compile_$scope";
        return $self->$method($inf);
    }

    method compile_functional { 'FUNCT CELL' }
    method compile_structural { 'STRUCT CELL' }

    method _is_closing (Str $value) {
        return defined $OpenerFor{ $value };
    }

    method _closer_for (Str $value) {
        return $CloserFor{ $value };
    }

    method new_from_stream (
        ClassName $class: 
            Object   $doc, 
            Object   $stream, 
            Str      $value,
            Location $loc
    ) {
        
        my $self = $class->new_from_value($value, $loc);

        while (my $token = $stream->next_token) {
            my ($token_type, $token_value, $token_location) = @$token;

            if ($self->_is_closing($token->[1])) {

                if ($self->_closer_for($value) eq $token->[1]) {

                    return $self;
                }
                else {

                    E_SYNTAX->throw(
                        message  => sprintf(
                            q(expected cell to be closed with '%s' (%s), not '%s' (%s)), 
                            $CloserFor{ $value }, 
                            $Name{ $value },
                            $token->[1],
                            $Name{ $token->[1] },
                        ),
                        location => $token_location,
                    );
                }
            }

            $self->add_node(my $node = $doc->new_node_from_stream($stream, $token));
        }

        E_SYNTAX->throw(
            location => $loc,
            message  => 'unexpected end of stream before cell was closed',
        );
    }

    method new_from_value (ClassName $class: Str $value, Location $loc) {

        my $specific_class = $class->_find_class($value)
            or E_SYNTAX->throw(
                location    => $loc,
                message     => sprintf(q(invalid cell opener '%s'), $value),
            );

        Class::MOP::load_class($specific_class);
        return $specific_class->new(location => $loc);
    }

    method _find_class (ClassName $class: Str $value) {

        my $specific_class = (

              $value eq CELL_APPLICATION    ? 'Application'
            : $value eq CELL_ARRAY          ? 'Application'
            : $value eq CELL_HASH           ? 'Hash'
            : undef
        );

        return undef
            unless $specific_class;

        return join '::', __PACKAGE__, $specific_class;
    }
}
