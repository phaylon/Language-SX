package Template::SX::Types;
use TryCatch;
use MooseX::Types -declare => [qw(
    Offset
    Scope
    Token
    LibraryList
    PairList
    Location
    QuoteState
)];

use MooseX::Types::Structured qw(
    Tuple
    Dict
);
use MooseX::Types::Moose qw( :all );

use Template::SX::Constants qw(
    SCOPE_STRUCTURAL
    SCOPE_FUNCTIONAL
);

use namespace::clean -except => 'import';

subtype Offset, 
     as Int, 
  where { $_ >= 0 };

enum QuoteState, qw( quasi full );

enum Scope, SCOPE_FUNCTIONAL, SCOPE_STRUCTURAL;

class_type $_ for map "Template::SX::$_", qw(
    Document
    Document::Bareword
    Document::Cell::Application
    Library
);

role_type $_ for map "Template::SX::$_", qw(
    Document::Locatable
);

subtype LibraryList, as ArrayRef[Object];

subtype PairList, as ArrayRef, where { @$_ == 2 };

subtype Location, as Dict[
    source  => Str, 
    line    => Int, 
    char    => Int, 
    context => Str,
    offset  => Int,
];

subtype Token, as Tuple[Str, Any, Location];

my $CoerceLib = sub {
    my $str = shift;
    my $obj;

    return $str 
        if ref $str;

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
