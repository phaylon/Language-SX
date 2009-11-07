use MooseX::Declare;

class Template::SX::Document::String::Constant 
    extends Template::SX::Document::Value {

    use Data::Dump           qw( pp );
    use Template::SX::Types  qw( Scope );

    method compile (Object $inf, Scope $scope) {

        return $inf->render_call(
            method  => 'make_constant',
            args    => {
                value   => pp($self->value),
            },
        );
    }

    method clean_end {

        my $val = $self->value;
        $val =~ s/ \s* \Z //xs;
        $self->value($val);
    }

    method clean_front {

        my $val = $self->value;
        $val =~ s/ \A \s* //xs;
        $self->value($val);
    }

    method clean_lines {

        my $val = $self->value;
        $val =~ s/ (?: ^ \s* | \s* $ ) //gxm;
        $self->value($val);
    }
}
