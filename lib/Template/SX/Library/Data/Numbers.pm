use MooseX::Declare;

class Template::SX::Library::Data::Numbers extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use List::AllUtils          qw( min max );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';

    CLASS->add_functions(
        '+' => sub { my $n = shift; $n += $_ for @_; $n || 0 },
        '-' => sub { my $n = shift; $n -= $_ for @_; $n || 0},
        '*' => sub { my $n = shift; $n *= $_ for @_; $n || 0},
        '/' => sub { my $n = shift; $n /= $_ for @_; $n || 0},
    );

    CLASS->add_functions(
        '<=>' => sub {

            E_PROTOTYPE->throw(
                class       => E_PARAMETER,
                attributes  => { message => '<=> expects exactly two numeric arguments' },
            ) unless @_ == 2;

            return $_[0] <=> $_[1];
        },
    );

    my $CheckManipArgs = sub {
        my $op = shift;

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => "function '$op' expects a single argument" },
        ) unless @_ == 1;
    };

    my $CheckScanArgs = sub {
        my $op = shift;

        E_PROTOTYPE->throw(
            class       => E_PARAMETER,
            attributes  => { message => "function '$op' expects one or more arguments" },
        ) unless @_ >= 1;
    };

    CLASS->add_functions(
        '=='    => CLASS->_build_equality_operator('=='),
        '!='    => CLASS->_build_nonequality_operator('!='), 
        '++'    => sub { $CheckManipArgs->('++', @_); $_[0] + 1 },
        '--'    => sub { $CheckManipArgs->('--', @_); $_[0] - 1 },
        '<'     => CLASS->_build_sequence_operator('<'),
        '>'     => CLASS->_build_sequence_operator('>'),
        '<='    => CLASS->_build_sequence_operator('<='),
        '>='    => CLASS->_build_sequence_operator('>='),
        min     => sub { $CheckScanArgs->('min', @_); min @_ },
        max     => sub { $CheckScanArgs->('max', @_); max @_ },
        'even?' => sub { 
            $CheckScanArgs->('even?', @_);
            return scalar( grep { $_ % 2 } @_ ) ? undef : 1;
        },
        'odd?'  => sub { 
            $CheckScanArgs->('odd?', @_);
            return scalar( grep { not($_ % 2) } @_ ) ? undef : 1;
        },
    );
}
