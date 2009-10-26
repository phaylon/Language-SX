use MooseX::Declare;

class Template::SX::Library::Data::Hashes extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_functions(hash => sub {

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => 'hash constructor expects even number of arguments' },
        ) if @_ % 2;

        return +{ @_ };
    });

    CLASS->add_functions('hash?', CLASS->wrap_function('hash?', { min => 1 }, sub {
        return scalar( grep { ref($_) ne 'HASH' } @_ ) ? undef : 1;
    }));

    CLASS->add_functions('hash-ref', CLASS->wrap_function('hash-ref', { min => 2, max => 2, types => [qw( hash )] }, sub {
        return $_[0]->{ $_[1] };
    }));

    CLASS->add_setter('hash-ref', CLASS->wrap_function('hash-ref', { min => 2, max => 2, types => [qw( hash )] }, sub {
        my ($hash, $key) = @_;
        return sub { $hash->{ $key } = shift };
    }));

    CLASS->add_functions('hash-splice', CLASS->wrap_function('hash-splice', { min => 2, max => 2, types => [qw( hash list )] }, sub {
        my ($hash, $keys) = @_;

        return +{ map {
            my ($idx, $key) = ($_, $keys->[ $_ ]);

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => sprintf 'entry %d in hash-splice key list is undefined', $idx + 1 },
            ) unless defined $key;

            ($key, $hash->{ $key }),
        } 0 .. $#$keys };
    }));

    CLASS->add_setter('hash-splice', CLASS->wrap_function('hash-splice', { min => 2, max => 2, types => [qw( hash list )] }, sub {
        my ($hash, $keys) = @_;

        for my $idx (0 .. $#$keys) {

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => sprintf 'entry %d in hash-splice setter key list is undefined', $idx + 1 },
            ) unless defined $keys->[ $idx ];
        }

        return sub {
            my $new = shift;

            E_PROTOTYPE->throw(
                class       => E_TYPE,
                attributes  => { message => 'new value for hash-splice has to be a hash' },
            ) unless ref $new eq 'HASH';

            my %spliced = map { ($_ => delete($hash->{ $_ })) } @$keys;

            $hash->{ $_ } = $new->{ $_ }
                for keys %$new;
        
            return \%spliced;
        };
    }));

    CLASS->add_functions(
        'merge' => CLASS->wrap_function('merge', { all_type => 'compound' }, sub {
            return +{ map {
                (ref($_) eq 'HASH') 
                ? (%$_) 
                : (do { 
                    no warnings 'misc'; 
                    %{ +{ @$_} }
                  }
                ) 
            } @_ };
        }),
        'hash-map' => CLASS->wrap_function('hash-map', { min => 2, max => 2, types => [qw( hash applicant )] }, sub {
            my ($hash, $apply) = @_;
            return +{ map {
                ($_, apply_scalar(apply => $apply, arguments => [$_, $hash->{ $_ }]))
            } keys %$hash };
        }),
        'hash-grep' => CLASS->wrap_function('hash-grep', { min => 2, max => 2, types => [qw( hash applicant )] }, sub {
            my ($hash, $apply) = @_;
            return +{ map { ($_, $hash->{ $_ }) } grep {
                apply_scalar apply => $apply, arguments => [$_, $hash->{ $_ }];
            } keys %$hash };
        }),
    );
}
