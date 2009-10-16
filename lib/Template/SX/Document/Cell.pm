use MooseX::Declare;

class Template::SX::Document::Cell 
    extends Template::SX::Document::Container {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );
    

    my @Pairs     = qw/ ( ) [ ] { } /;
    my %OpenerFor = reverse @Pairs;
    my %CloserFor = @Pairs;


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
            Str      $value
    ) {
        
        my $self = $class->new_from_value($value);

        while (my $token = $stream->next_token) {

            if ($self->_is_closing($token->[1])) {

                if ($self->_closer_for($value) eq $token->[1]) {

                    return $self;
                }
                else {

                    # FIXME throw exception
                    die "Expected closing $value, not $token->[1]";
                }
            }

            $self->add_node(my $node = $doc->new_node_from_stream($stream, $token));
        }

        # FIXME throw exception
        die "Expected closing $value, not end of stream";
    }

    method new_from_value (ClassName $class: Str $value) {

        # FIXME throw exception
        my $specific_class = $class->_find_class($value)
            or die "Cell opener '$value' is invalid\n";

        Class::MOP::load_class($specific_class);

        return $specific_class->new;
    }

    method _find_class (ClassName $class: Str $value) {

        my $specific_class = (

              $value eq CELL_APPLICATION    ? 'Application'
            : $value eq CELL_ARRAY          ? 'Array'
            : $value eq CELL_HASH           ? 'Hash'
            : undef
        );

        return undef
            unless $specific_class;

        return join '::', __PACKAGE__, $specific_class;
    }
}
