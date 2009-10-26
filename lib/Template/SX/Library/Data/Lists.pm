use MooseX::Declare;

class Template::SX::Library::Data::Lists extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use List::Util              qw( first reduce );
    use List::MoreUtils         qw( any all );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_functions(list => sub { [@_] });

    CLASS->add_functions('list?' => CLASS->wrap_function('list?', { min => 1 }, sub {
        return scalar(grep { ref($_) ne 'ARRAY' } @_) ? undef : 1;
    }));

    CLASS->add_functions('list-ref', CLASS->wrap_function('list-ref', { min => 2, max => 2, types => [qw( list )] }, sub {
        return $_[0]->[ $_[1] ];
    }));
    CLASS->add_setter('list-ref', CLASS->wrap_function('list-ref', { min => 2, max => 2, types => [qw( list )] }, sub {
        my ($ls, $idx) = @_;
        return sub { $ls->[ $idx ] = shift };
    }));

    CLASS->add_functions(
        'any?'  => CLASS->wrap_function('any?', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return scalar( any { apply_scalar apply => $apply, arguments => [$_] } @$ls ) ? 1 : undef;
        }),
        'all?'  => CLASS->wrap_function('all?', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return scalar( all { apply_scalar apply => $apply, arguments => [$_] } @$ls ) ? 1 : undef;
        }),
    );

    CLASS->add_functions(
        gather => CLASS->wrap_function('gather', { min => 1, types => [qw( lambda )] }, sub {
            my ($collector, @args) = @_;

            my @collected;
            my $taker = sub { push @collected, @_ };

            apply_scalar apply => $collector, arguments => [$taker, @args];

            return \@collected;
        }),
    );

    CLASS->add_functions(
        'n-at-a-time' => CLASS->wrap_function('n-at-a-time', { min => 3, max => 3, types => [qw( any list applicant )] }, sub {
            my ($num, $ls, $apply) = @_;

            my $offset = 0;
            my @collected;

            while ($offset <= $#$ls) {

                push @collected, apply_scalar
                    apply       => $apply,
                    arguments   => [@{ $ls }[ $offset .. $offset + $num - 1 ]];

                $offset += $num;
            }

            return \@collected;
        }),
    );

    CLASS->add_functions(
        'list-splice' => CLASS->wrap_function('list-splice', { min => 2, max => 3, types => [qw( list )] }, sub {
            my ($ls, $start, $length) = @_;

            return [ 
                @{ $ls }[+$start .. (@_ == 3 ? ($start + $length - 1) : $#$ls)]
            ];
        }),
    );

    CLASS->add_setter(
        'list-splice' => CLASS->wrap_function('list-splice', { min => 2, max => 3, types => [qw( list )] }, sub {
            my ($ls, $start, $length) = @_;
            my $has_length = @_ == 3;

            return sub {
                my $new = shift;
                
                E_PROTOTYPE->throw(
                    class       => E_TYPE,
                    attributes  => { message => 'list-splice setter expects to receive a list as value' },
                ) unless ref $new eq 'ARRAY';

                unless ($has_length) {
                    $length = @$ls - $start;
                }

                my @old = @{ $ls }[+$start .. ($start + $length - 1)];

                @$ls = (
                    @{ $ls }[0 .. $start - 1],
                    @$new,
                    @{ $ls }[($start + $length) .. $#$ls],
                );

                return \@old;
            };
        }),
    );

    CLASS->add_functions(
        map     => CLASS->wrap_function('map', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return [ map { apply_scalar apply => $apply, arguments => [$_] } @$ls ];
        }),
        first   => CLASS->wrap_function('grep', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return scalar first { apply_scalar apply => $apply, arguments => [$_] } @$ls;
        }),
        grep    => CLASS->wrap_function('grep', { min => 2, max => 2, types => [qw( list applicant )] }, sub {
            my ($ls, $apply) = @_;
            return [ grep { apply_scalar apply => $apply, arguments => [$_] } @$ls ];
        }),
        sort    => CLASS->wrap_function('sort', { min => 2, max => 2, types => [qw( list lambda )] }, sub {
            my ($ls, $apply) = @_;
            return [ sort { apply_scalar apply => $apply, arguments => [$a, $b] } @$ls ];
        }),
        append  => CLASS->wrap_function('append', { all_type => 'compound' }, sub {
            return [ map { (ref eq 'ARRAY') ? (@$_) : (%$_) } @_ ];
        }),
        join    => CLASS->wrap_function('join', { min => 2, max => 2, types => [qw( any list )] }, sub {
            return join($_[0], @{ $_[1] });
        }),
        head    => CLASS->wrap_function('head', { min => 1, max => 1, types => [qw( list )] }, sub {
            return $_[0]->[0];
        }),
        tail    => CLASS->wrap_function('tail', { min => 1, max => 1, types => [qw( list )] }, sub {
            return [ @{ $_[0] }[1 .. $#{ $_[0] }] ];
        }),
        reduce  => CLASS->wrap_function('reduce', { min => 2, max => 2, types => [qw( list lambda )] }, sub {
            my ($ls, $apply) = @_;
            return scalar reduce { apply_scalar apply => $apply, arguments => [$a, $b] } @$ls;
        }),
        uniq    => CLASS->wrap_function('uniq', { min => 1, max => 2, types => [qw( list lambda )] }, sub {
            my ($ls, $get_value) = @_;

            my @found;
            my %seen;

            for my $item (@$ls) {

                my $value = $get_value 
                    ? apply_scalar(apply => $get_value, arguments => [$item])
                    : "$item";

                next if $seen{ $value }++;

                push @found, $item;
            }

            return \@found;
        }),
    );
}

