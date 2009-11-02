use MooseX::Declare;

class Template::SX::Library::Data::Functions extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );
    use Scalar::Util            qw( blessed );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_functions(apply => sub {
        my ($op, @args) = @_;

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => 'apply expects at least two arguments' },
        ) unless @_ >= 2;

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => 'last argument to apply has to be a list' },
        ) unless ref $args[-1] eq 'ARRAY';

        push @args, @{ pop @args };
        return apply_scalar apply => $op, arguments => \@args;
    });

    CLASS->add_functions(
        while => CLASS->wrap_function('while', { min => 3, max => 3, types => [qw( lambda lambda applicant )] }, sub {
            my ($get, $test, $apply) = @_;

            my $value;
            while ($test->(my $next = $get->())) {
                apply_scalar apply => $apply, arguments => [$next];
                $value = $next;
            }

            return $value;
        }),
    );

    CLASS->add_functions(
        curry => CLASS->wrap_function('curry', { min => 2, types => [qw( applicant )] }, sub {
            my ($apply, @args) = @_;
            return sub {
                return apply_scalar
                    apply       => $apply,
                    arguments   => [@args, @_];
            };
        }),
        rcurry => CLASS->wrap_function('rcurry', { min => 2, types => [qw( applicant )] }, sub {
            my ($apply, @args) = @_;
            return sub {
                return apply_scalar
                    apply       => $apply,
                    arguments   => [@_, @args];
            };
        }),
    );

    CLASS->add_functions('lambda?', sub {

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => 'lambda predicate expects at least one argument' },
        ) unless @_;

        return scalar( grep { ref $_ ne 'CODE' } @_ ) ? undef : 1;
    });

    CLASS->add_functions('cascade', sub {

        return undef unless @_;

        my $value = shift @_;

        for my $idx (0 .. $#_) {
            my $apply = $_[ $idx ];

            return undef unless defined $value;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => sprintf 'cascade argument %s is not a valid applicant', $idx + 1 },
            ) unless blessed($apply) or ref $apply eq 'CODE';

            $value = apply_scalar apply => $apply, arguments => [$value];
        }

        return $value;
    });
}
