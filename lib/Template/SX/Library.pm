use MooseX::Declare;

class Template::SX::Library {

    use Sub::Name;
    use MooseX::Types::Moose    qw( HashRef CodeRef );
    use MooseX::ClassAttribute;
    use Template::SX::Constants qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has function_map => (
        traits      => [qw( Hash )],
        isa         => HashRef[CodeRef],
        default     => sub { {} },
        handles     => {
            _add_functions  => 'set',
            get_functions   => 'get',
            _has_function   => 'exists',
            function_names  => 'keys',
        },
    );

    method add_functions (ClassName $class: @args) {

        my %functions = @args;
        $class->_add_functions(map {
            ($_, subname "${class}::function[${_}]", $functions{ $_ }),
        } keys %functions);
    }

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

    class_has setter_map => (
        traits      => [qw( Hash )],
        isa         => HashRef[CodeRef],
        default     => sub { {} },
        handles     => {
            add_setter      => 'set',
            get_setter      => 'get',
            _has_setter     => 'exists',
            setter_names    => 'keys',
        },
    );

    method has_setter (Str $name) {
        return undef unless $self->_has_setter($name);
        return $self;
    }

    method has_function (Str $name) {
        return undef unless $self->_has_function($name);
        return $self;
    }

    method has_syntax (Str $name) {
        return undef unless $self->_has_syntax($name);
        return $self;
    }

    method additional_inflator_traits { () }

    method _build_sequence_operator (ClassName $class: Str $op, Str $name?) {

        $name ||= $op;

        return eval q/
            sub {
                return scalar(
                    grep { not( $_[ $_ ] / . $op . q/ $_[ $_ + 1 ] ) } 0 .. $#_ - 1
                ) ? undef : 1;
            };
        /;
    }

    method _build_unary_builtin_function (ClassName $class: Str $builtin, Str $name) {

        $name ||= $builtin;

        return $class->wrap_function($name, { min => 1, max => 1 }, eval sprintf 'sub { %s($_[0]) }', $builtin);
    }

    method _build_equality_operator (ClassName $class: Str $op, Str $name?) {

        $name ||= $op;

        return eval q/
            sub {

                /.E_PROTOTYPE.q/->throw(
                    class       => '/.E_PARAMETER.q/',
                    attributes  => { message => "function '/.$name.q/' expects at least two arguments" },
                ) unless @_ >= 2;

                my $x = shift;
                return scalar( grep { not( $x /.$op.q/ $_ ) } @_ ) ? undef : 1;
            };
        /;
    }

    method _build_nonequality_operator (ClassName $class: Str $op, Str $name?) {

        $name ||= $op;

        return eval q/
            sub {

                /.E_PROTOTYPE.q/->throw(
                    class       => '/.E_PARAMETER.q/',
                    attributes  => { message => "function '/.$name.q/' expects at least two arguments" },
                ) unless @_ >= 2;

                for my $x (0 .. $#_) {
                    for my $y ($x + 1 .. $#_) {
                        return undef
                            unless $_[ $x ] /.$op.q/ $_[ $y ];
                    }
                }
                return 1;
            };
        /;
    }

    my %TypeCheck = (
        list        => sub { ref $_[0] eq 'ARRAY' },
        hash        => sub { ref $_[0] eq 'HASH' },
        object      => sub { blessed($_[0]) and not $_[0]->isa('Moose::Meta::TypeConstraint') },
        type        => sub { blessed($_[0]) and $_[0]->isa('Moose::Meta::TypeConstraint') },
        lambda      => sub { ref $_[0] eq 'CODE' },
        regex       => sub { ref $_[0] eq 'Regexp' },
        word        => sub { blessed($_[0]) and $_[0]->isa('Template::SX::Document::Bareword') },
        any         => sub { 1 },
        applicant   => sub { (blessed($_[0])) or ref($_[0]) eq 'CODE' },
        compound    => sub { ref($_[0]) eq 'ARRAY' or ref($_[0]) eq 'HASH' },
        string      => sub { defined($_[0]) and not ref($_[0]) },
    );
    $TypeCheck{enum} = sub { blessed($_[0]) and $_[0]->isa('Moose::Meta::TypeConstraint::Enum') };

    method wrap_function (ClassName $class: Str $name, HashRef $args, CodeRef $body) {
        my $min = $args->{min} || 0;
        my $max = $args->{max};

        my @type_names  = @{ $args->{types} || [] };
        my @types       = map { $TypeCheck{ $_ } } @type_names;
        my $all_type    = $args->{all_type} && $TypeCheck{ $args->{all_type} };
        my $all_name    = $args->{all_type};
        my $subname     = "${class}::function[$name]";

        subname $subname, $body;

        return subname $subname => sub {

            E_PROTOTYPE->throw(
                class       => E_PARAMETER, 
                attributes  => { 
                    message => sprintf(
                        'not enough arguments for %s (expected %d, received %d)', 
                        $name,
                        $min,
                        scalar(@_),
                    ),
                },
            ) unless @_ >= $min;

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => {
                    message => sprintf(
                        'too many arguments for %s (would accept %d, received %d)',
                        $name,
                        $max,
                        scalar(@_),
                    ),
                },
            ) if defined($max) and @_ > $max;

            for my $idx (0 .. $#_) {
                last if not($all_type) and $idx > $#types;

                E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => {
                        message => sprintf(
                            'argument %d to %s has to be a %s',
                            $idx + 1,
                            $name,
                            ($all_type ? $all_name : $type_names[ $idx ] ),
                        ),
                    },
                ) unless ($all_type ? $all_type : $types[ $idx ])->($_[ $idx ]);
            }

            goto $body;
        };
    }
}
