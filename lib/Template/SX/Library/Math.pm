use MooseX::Declare;

class Template::SX::Library::Math extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    class_has '+syntax_map';
    class_has '+function_map';

    CLASS->add_functions(
        '+' => sub { my $n = shift; $n += $_ for @_; $n },
        '-' => sub { my $n = shift; $n -= $_ for @_; $n },
        '*' => sub { my $n = shift; $n *= $_ for @_; $n },
        '/' => sub { my $n = shift; $n /= $_ for @_; $n },
    );
}
