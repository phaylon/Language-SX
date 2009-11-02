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
    SourceType
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
    Reader
    Reader::Stream
    Document
    Document::Bareword
    Document::Cell::Application
    Exception
    Exception::Prototype
    Exception::Syntax
    Exception::Syntax::EndOfStream
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

enum SourceType, qw( string file handle );

subtype Token, as Tuple[Str, Any, Location];

my $CoerceLib = sub {
    my $str = shift;
    my $obj;

    return $str 
        if ref $str;

    my @errors;

    for my $try ($str, "Template::SX::Library::$str") {

        try {
            Class::MOP::load_class($try);
            $obj = $try->new;
        }
        catch (Any $e) { 
            push @errors, $e;
        }
    }

    # FIXME throw exception
    die sprintf "Unable to load library %s:\n%s\n", $str, join("\n", @errors)
        unless $obj;

    return $obj;
};

coerce LibraryList,
    from ArrayRef[Str | 'Template::SX::Library'], 
        via { [map { ref() ? $_ : $CoerceLib->($_) } @$_] };

1;
