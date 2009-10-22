use MooseX::Declare;

class Template::SX::Document::Value 
    with Template::SX::Document::Locatable {

    use Template::SX::Types     qw( :all );
    use MooseX::Types::Moose    qw( Value );

    has value => (
        is          => 'rw',
        isa         => Value,
        required    => 1,
    );

    method compile (Object $inf, Scope $scope) {

        my $method = "compile_$scope";
        return $self->$method($inf);
    }

    method new_from_stream (ClassName $class: Object $doc, Object $stream, Str $value, Location $loc) {

        return $class->new(value => $value, location => $loc);
    }
}
