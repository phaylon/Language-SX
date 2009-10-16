use MooseX::Declare;

class Template::SX::Library::Math extends Template::SX::Library {
    use CLASS;

    CLASS->add_functions(
        '+' => sub { my $n = shift; $n += $_ for @_; $n },
        '-' => sub { my $n = shift; $n -= $_ for @_; $n },
        '*' => sub { my $n = shift; $n *= $_ for @_; $n },
        '/' => sub { my $n = shift; $n /= $_ for @_; $n },
    );
}
