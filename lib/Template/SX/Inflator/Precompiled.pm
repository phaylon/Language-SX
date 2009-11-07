use MooseX::Declare;

class Template::SX::Inflator::Precompiled with Template::SX::Document::Locatable {

    use MooseX::Types::Moose qw( Str );

    has compiled => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
    );

    method compile { $self->compiled }
}
