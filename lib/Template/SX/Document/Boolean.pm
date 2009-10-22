use MooseX::Declare;

class Template::SX::Document::Boolean extends Template::SX::Document::Value {
    
    use Data::Dump qw( pp );
    use MooseX::Types::Moose qw( Bool );

    my %ValueMap = (t => 1, true => 1, yes => 1, f => undef, false => undef, no => undef);

    method compile (Object $inf, @) {

        return $inf->render_call(
            method  => 'make_boolean_constant',
            args    => { value => pp($ValueMap{ $self->value }) },
        );
    }
}
