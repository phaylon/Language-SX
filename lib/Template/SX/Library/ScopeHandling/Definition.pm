use MooseX::Declare;

class Template::SX::Library::ScopeHandling::Definition 
    with Template::SX::Inflator::ImplicitScoping {

    use Template::SX::Types         qw( :all );
    use Template::SX::Constants     qw( :all );
    use Data::Dump                  qw( pp );
    use MooseX::Types::Moose        qw( Object Str HashRef Undef );
    use MooseX::Types::Structured   qw( Tuple );

    has variable_map => (
        traits      => [qw( Hash )],
        isa         => HashRef[Tuple[Object, Object | Undef]],
        required    => 1,
        handles     => {
            variable_names  => 'keys',
            variable_source => 'get',
        },
    );

    method new_from_mapping (ClassName $class: PairList[Object | Undef] $mapping) {

        my @map = @$mapping;
        my %post;

        while (my $name_from = shift @map) {
            my $value_from = shift @map;

            # FIXME throw exception
            die "name must be bareword"
                unless $name_from->isa('Template::SX::Document::Bareword');

            my $name = $name_from->value;

            # FIXME throw exception
            die "cannot define variable twice in same scope"
                if exists $post{ $name };

            $post{ $name } = [$name_from, $value_from];
        }

        return $class->new(variable_map => \%post);
    }

    method render_variable_map (Object $inf) {

        return sprintf(
            '{ %s }', join(
                ', ',
                map {
                    my $source = $self->variable_source($_);
                    join(
                        ', ',
                        pp($_),
                        $source->[1] ? $source->[1]->compile($inf, SCOPE_FUNCTIONAL) : 'sub { undef }'
                    );
                } $self->variable_names
            ),
        );
    }

    method compile_scoped (Object $inf, ArrayRef[Object] $nodes) {

        for my $identifier ($self->variable_names) {

            $inf->assure_unreserved_identifier($self->variable_source($identifier)->[0]);
        }

        return $inf->render_call(
            library     => 'Template::SX::Library::ScopeHandling',
            method      => 'make_definition_scope',
            args        => {
                vars        => $self->render_variable_map($inf),
              ( @$nodes             
                ? ( sequence => $inf->render_call(
                        method  => 'make_sequence',
                        args    => {
                            elements    => sprintf(
                                '[%s]', join(
                                    ', ',
                                    $inf->compile_sequence($nodes, SCOPE_FUNCTIONAL)
                                ),
                            ),
                        },
                  ) )
                : () ),
            },
        );
    }
}
