use MooseX::Declare;

class Template::SX::Inflator::ValueScope {

    class ::Variable with Template::SX::Document::Locatable {

        use Data::Dump              qw( pp );
        use MooseX::Types::Moose    qw( Int Str );

        my $LastID = 0;

        has id => (
            is          => 'ro',
            isa         => Int,
            init_arg    => undef,
            required    => 1,
            default     => sub { $LastID++ },
        );

        has prefix => (
            is          => 'ro',
            isa         => Str,
            required    => 1,
        );

        has scopename => (
            is          => 'ro',
            isa         => Str,
            required    => 1,
        );

        method name { join '_' => $self->prefix, $self->id }

        method compile { sprintf '%s->(getter_for => %s)', $self->scopename, pp($self->name) }
    }

    use MooseX::Types::Moose    qw( Object HashRef Int ArrayRef );
    use Template::SX::Constants qw( :all );
    use Data::Dump              qw( pp );

    has variables => (
        traits      => [qw( Hash )],
        isa         => HashRef[Object],
        required    => 1,
        default     => sub { {} },
        handles     => {
            _var_count  => 'count',
            _var_set    => 'set',
            _var_source => 'get',
            _var_names  => 'keys',
        },
    );

    my $LastScopeID = 0;

    has id => (
        is          => 'ro',
        isa         => Int,
        init_arg    => undef,
        required    => 1,
        default     => sub { $LastScopeID++ },
    );

    method varname { join '_', '$SCOPE', $self->id }
    
    method add_variable (Object $source, Str $name = "anon") {
        
        my $var = Template::SX::Inflator::ValueScope::Variable->new(
            prefix      => $name,
            location    => $source->location,
            scopename   => $self->varname,
        );

        $self->_var_set($var->name, $source);

        return $var;
    }

    method wrap (Str $body, Object $inf) {

        return $body unless $self->_var_count;

        return sprintf(
            '(do { my %s = %s; %s->(enclose => %s) })',
            $self->varname,
            $inf->render_call(
                library => 'Template::SX::Library::ScopeHandling',
                method  => 'make_value_scope',
                args    => {
                    variables => sprintf(
                        '(+{ %s })',
                        join(', ',
                            map {
                                (pp($_), $self->_var_source($_)->compile($inf, SCOPE_FUNCTIONAL))
                            } $self->_var_names,
                        ),
                    ),
                },
            ),
            $self->varname,
            $body,
        );
    }
}
