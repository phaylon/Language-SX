use MooseX::Declare;

class Template::SX::Library {

    use MooseX::Types::Moose    qw( HashRef CodeRef );
    use MooseX::ClassAttribute;

    class_has function_map => (
        traits      => [qw( Hash )],
        isa         => HashRef[CodeRef],
        default     => sub { {} },
        handles     => {
            add_functions   => 'set',
            get_functions   => 'get',
            _has_function   => 'exists',
            function_names  => 'keys',
        },
    );

    class_has syntax_map => (
        traits      => [qw( Hash )],
        isa         => HashRef[CodeRef],
        default     => sub { {} },
        handles     => {
            add_syntax      => 'set',
            get_syntax      => 'get',
            _has_syntax     => 'exists',
            syntax_names    => 'keys',
        },
    );

    method has_function (Str $name) {
        return undef unless $self->_has_function($name);
        return $self;
    }

    method has_syntax (Str $name) {
        return undef unless $self->_has_syntax($name);
        return $self;
    }

    method additional_inflator_traits { () }
}
