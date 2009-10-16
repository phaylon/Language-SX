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
            has_function    => 'exists',
            function_names  => 'keys',
        },
    );
}
