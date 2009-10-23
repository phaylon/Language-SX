use MooseX::Declare;

class Template::SX::Library::Data::Numbers extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

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
}
