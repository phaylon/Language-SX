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

    CLASS->add_setter(
        'values' => CLASS->wrap_function('values', { min => 1, max => 2, types => [qw( compound list )] }, sub {
            my ($target, $keys) = @_;

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => 'setting hash values requires a list of keys' },
            ) if not($keys) and ref $target eq 'HASH';

            if ($keys) {
    
                for my $idx (0 .. $#$keys) {

                    E_PROTOTYPE->throw(
                        class       => E_TYPE,
                        attributes  => { message => sprintf 'value setter key list item %d is undefined', $idx + 1 },
                    ) unless defined $keys->[ $idx ];
                }
            }

            return sub {
                my $new = shift;

                E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => 'values setter expects a list of new values' },
                ) unless ref $new eq 'ARRAY';

                E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => sprintf 'unable to save %d values under %d keys', scalar(@$new), scalar(@$keys) },
                ) if $keys and @$new != @$keys;

                my @old;

                if (ref $target eq 'HASH') {
                    @old = @{ $target }{ @$keys };
                    @{ $target }{ @$keys } = @$new;
                }
                else {
                    if ($keys) {
                        @old = @{ $target }[ @$keys ];
                        @{ $target }[ @$keys ] = @$new;
                    }
                    else {
                        @old = @$target;
                        @$target = @$new;
                    }
                }

                return \@old;
            };
        }),
    );

    CLASS->add_functions(
        'defined?' => sub {
            return undef unless @_;
            return undef if grep { not defined } @_;
            return 1;
        },
        'reverse' => CLASS->wrap_function('reverse', { min => 1, max => 1, types => [qw( any )] }, sub {
            my $item = shift;

            return(
                ( ref($item) eq 'HASH' )                  ? { reverse %$item }
              : ( ref($item) eq 'ARRAY' )                 ? [ reverse @$item ]
              : ( not(ref($item)) and defined($item) )    ? reverse("$item")
              : E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => sprintf(q(unable to reverse '%s'), $item) },
                )
            );
        }),
        'length' => CLASS->wrap_function('length', { min => 1, max => 1 }, sub {
            my $item = shift;

            return
                ( ref($item) eq 'ARRAY' )   ? scalar(@$item)
              : ( ref($item) eq 'HASH' )    ? scalar(keys %$item)
              : ( not ref $item )           ? length($item)
              : E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => sprintf(q(unable to calculate length from '%s'), $item) },
                );
        }),
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

            if ($keys) {

                for my $idx (0 .. $#$keys) {

                    E_PROTOTYPE->throw(
                        class       => E_TYPE,
                        attributes  => { message => sprintf 'values key list item %d is undefined', $idx + 1 },
                    ) unless defined $keys->[ $idx ];
                }
            }

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

