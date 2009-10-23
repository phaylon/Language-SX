use MooseX::Declare;

class Template::SX::Library::Data::Common extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use TryCatch;
    use Data::Dump              qw( pp );
    use Scalar::Util            qw( blessed );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_functions(
        'empty?' => sub {

            for my $n (@_) {
                
                next if not( defined $n )
                     or (
                        ref($n)
                        ? ( ref($n) eq 'HASH'  ? not( keys %$n )
                          : ref($n) eq 'ARRAY' ? not( @$n )
                          : 0
                        )
                        : not( length $n )
                     );

                return undef;
            }

            return 1;
        },
        'keys' => sub {
            
            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'keys expects one hash or list argument' },
            ) unless @_ == 1;

            my $arg = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'argument to keys is not a hash or list' },
            ) unless ref $arg eq 'HASH' or ref $arg eq 'ARRAY';

            return +( ref $arg eq 'HASH' ) ? [keys %$arg] : [0 .. $#$arg];
        },
        values => sub {
            
            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'values expects a required data and an optional key list argument' },
            ) unless @_ == 1 or @_ == 2;

            my $arg  = shift; my $arg_ref  = ref $arg;
            my $keys = shift; my $keys_ref = ref $keys;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'key list argument to values must be a list' },
            ) if defined $keys and $keys_ref ne 'ARRAY';

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'data argument to values is not a hash or list' },
            ) unless $arg_ref eq 'HASH' or $arg_ref eq 'ARRAY';

            if ($arg_ref eq 'ARRAY') {
                return [ $keys ? @{ $arg }[ @$keys ] : @$arg ];
            }
            else {
                return [ $keys ? @{ $arg }{ @$keys } : values %$arg ];
            }
        },
    );

    method _build_deep_getter (ClassName $class: CodeRef :$on_last?) {

        return sub {
            my ($data, @path) = @_;

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'deep data structure access requires at least the data structure argument' },
            ) unless @_;

            for my $idx (0 .. $#path) {
                my $key = $path[ $idx ];

                E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => "data path item at position $idx (starting with 0) is undefined" },
                ) unless defined $key;

                if ($on_last and $idx == $#path) {
                    return $on_last->($data, $key);
                }

                if (ref $data eq 'ARRAY') {
                    return undef unless exists $data->[ $key ];
                    $data = $data->[ $key ];
                }
                elsif (ref $data eq 'HASH') {
                    return undef unless exists $data->{ $key };
                    $data = $data->{ $key };
                }
                elsif (blessed $data) {
                    return undef unless $data->can($key);
                    $data = apply_scalar apply => $data, arguments => [$key];
                }
                else {
                    return undef;
                }
            }

            return $data;
        };
    }

    CLASS->add_functions('exists?' => CLASS->_build_deep_getter(
        on_last => sub {
            ref($_[0]) eq 'HASH'    ? ( exists($_[0]->{ $_[1] }) ? 1 : undef )
          : ref($_[0]) eq 'ARRAY'   ? ( exists($_[0]->[ $_[1] ]) ? 1 : undef )
          : blessed($_[0])          ? ( $_[0]->can($_[1])        ? 1 : undef )
          : undef
        },
    ));

    CLASS->add_functions(at => CLASS->_build_deep_getter);
}

