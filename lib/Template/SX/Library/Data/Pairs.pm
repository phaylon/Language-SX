use MooseX::Declare;

class Template::SX::Library::Data::Pairs extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Name;
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    my $ListToPairs = sub {
        my @ls = @{ $_[0] };

        E_PROTOTYPE->throw(
            class       => E_TYPE,
            attributes  => { message => 'unable to convert odd-sized list to list of pairs' },
        ) if scalar(@ls) % 2;

        my @pairs;
        while (my $key = shift @ls) {
            push @pairs, [$key, shift @ls];
        }

        return \@pairs;
    };

    my $HashToPairs = sub {
        my $hash = shift;

        return [ map { [$_, $hash->{ $_ }] } keys %$hash ];
    };

    CLASS->add_functions(
        'list->pairs'       => CLASS->wrap_function('list->pairs',      { min => 1, max => 1, types => [qw( list )] }, $ListToPairs),
        'hash->pairs'       => CLASS->wrap_function('hash->pairs',      { min => 1, max => 1, types => [qw( hash )] }, $HashToPairs),
        'compound->pairs'   => CLASS->wrap_function('compound->pairs',  { min => 1, max => 1, types => [qw( compound )] }, sub {
            my $comp = shift;
            
            return(
              ( (ref $comp eq 'HASH')
                ? $HashToPairs
                : $ListToPairs 
              )->($comp)
            );
        }),
    );

    my $IsPair = sub {

        for my $item (@_) {

            return undef unless ref $item eq 'ARRAY';
            return undef unless @$item == 2;
        }

        return 1;
    };

    my $IsPairList = sub {

        for my $list (@_) {

            return undef unless ref $list eq 'ARRAY';
            return undef unless $IsPair->(@$list);
        }

        return 1;
    };

    CLASS->add_functions(
        'pair?'  => CLASS->wrap_function('pair?',  { min => 1 }, $IsPair),
        'pairs?' => CLASS->wrap_function('pairs?', { min => 1 }, $IsPairList),
    );

    CLASS->add_functions(
        'pairs->list' => CLASS->wrap_function('pairs->list', { min => 1, max => 1 }, sub {
            my $pl = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'argument to pairs->list has to be a pair list' },
            ) unless $pl->$IsPairList;

            return [ map { (@$_) } @$pl ];
        }),
        'pairs->hash' => CLASS->wrap_function('pairs->hash', { min => 1, max => 1 }, sub {
            my $pl = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'argument to pairs->hash has to be a pair list' },
            ) unless $pl->$IsPairList;

            return +{ map { (@$_) } @$pl };
        }),
    );
}
