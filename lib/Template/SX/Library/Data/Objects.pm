use MooseX::Declare;

class Template::SX::Library::Data::Objects extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Call::Tail;
    use Scalar::Util            qw( blessed );
    use Sub::Name               qw( subname );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';

    CLASS->add_functions(
        'object?' => CLASS->wrap_function('object', { min => 1 }, sub {
            return scalar( grep { not blessed $_ } @_ ) ? undef : 1;
        }),
        'class-of' => CLASS->wrap_function('class-of', { min => 1, max => 1, types => [qw( object )] }, sub {
            return blessed shift;
        }),
    );

    CLASS->add_functions(
        'object-invocant' => CLASS->wrap_function('object-invocant', { min => 1, max => 1 }, sub {
            my $object = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'argument to object-invocant must be a blessed reference' },
            ) unless blessed $object;

            return subname OBJECT_INVOCATION => sub {

                E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => 'object invocant expects at least a method argument' },
                ) unless @_;

                my ($method, @args) = @_;
                tail $object->$method(@args);
            };
        }),
        'class-invocant' => CLASS->wrap_function('class-invocant', { min => 1, max => 1 }, sub {
            my $class_from = shift;

            my $class = (
                blessed($class_from)                            ? blessed($class_from)
              : (defined($class_from) and not ref($class_from)) ? $class_from
              : E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => 'argument to class-invocant must be a blessed reference or class name' }
                )
            );

            return subname CLASS_INVOCATION => sub {

                E_PROTOTYPE->throw(
                    class       => E_PARAMETER,
                    attributes  => { message => 'class invocant expects at least a method argument' },
                ) unless @_;

                my ($method, @args) = @_;
                tail $class->$method(@args);
            };
        }),
    );
}
