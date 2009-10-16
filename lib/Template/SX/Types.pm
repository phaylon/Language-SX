package Template::SX::Types;
use TryCatch;
use MooseX::Types -declare => [qw(
    Offset
    Scope
    Token
    LibraryList
)];

use MooseX::Types::Structured qw(
    Tuple
);
use MooseX::Types::Moose qw(
    Int
    ArrayRef
    Str
    Any
    Object
);

use Template::SX::Constants qw(
    SCOPE_STRUCTURAL
    SCOPE_FUNCTIONAL
);

use namespace::clean -except => 'import';

subtype Offset, as Int, where { $_ >= 0 };

enum Scope, SCOPE_FUNCTIONAL, SCOPE_STRUCTURAL;

subtype Token, as Tuple[Str, Any];

class_type $_ for map "Template::SX::$_", qw(
    Document
    Document::Bareword
    Library
);

subtype LibraryList, as ArrayRef[Object];

my $CoerceLib = sub {
    my $str = shift;
    my $obj;

    for my $try ($str, "Template::SX::Library::$str") {
        try {
            Class::MOP::load_class($try);
            $obj = $try->new;
        }
    }

    # FIXME throw exception
    die "Unable to load library: $str\n"
        unless $obj;

    return $obj;
};

coerce LibraryList,
    from ArrayRef[Str | 'Template::SX::Library'], 
        via { [map { ref() ? $_ : $CoerceLib->($_) } @$_] };

1;
