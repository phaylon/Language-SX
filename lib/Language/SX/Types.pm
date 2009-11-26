package Language::SX::Types;
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

use Language::SX::Constants qw(
    SCOPE_STRUCTURAL
    SCOPE_FUNCTIONAL
);


subtype Offset, 
     as Int, 
  where { $_ >= 0 };

enum QuoteState, qw( quasi full );

enum Scope, SCOPE_FUNCTIONAL, SCOPE_STRUCTURAL;

class_type $_ for map "Language::SX::$_", qw(
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
    Inflator
);

role_type $_ for map "Language::SX::$_", qw(
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

    for my $try ($str, "Language::SX::Library::$str") {

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
    from ArrayRef[Str | 'Language::SX::Library'], 
        via { [map { ref() ? $_ : $CoerceLib->($_) } @$_] };

1;

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also MooseX::Types
@see_also Moose::Manual::Types
@license  Language::SX

@typelib Language::SX::Types
Types required for L<Language::SX>

@type Offset
A non-negative integer.

@type LibraryList
A list of library objects.

@type PairList
A list of pairs

@type Token
An array reference containing the type, value and location identifying a token.

@type Scope
Compilation scope.

@type QuoteState
Type of quotation environment. C<quasi> allows interpolation, C<full> doesn't.

@type SourceType
Type of source that is read.

@type Location
Record containing a position and context in the source.

=end fusion






=head1 NAME

Language::SX::Types - Types required for L<Language::SX>

=head1 TYPES

=head2 Offset

Subtype of Int

A non-negative integer.

=head2 LibraryList

Subtype of ArrayRef[Object]

Available coercions:

=over

=item * ArrayRef[Str|L<Language::SX::Library>]

=back

A list of library objects.

=head2 PairList

Subtype of ArrayRef

A list of pairs

=head2 Token

Subtype of L<Tuple|MooseX::Types::Structured/Tuple>[Str,Any,L<Location|Language::SX::Types/Location>]

An array reference containing the type, value and location identifying a token.

=head2 Scope

Subtype of Str

Valid values:

=over

=item * C<functional>

=item * C<structural>

=back

Compilation scope.

=head2 QuoteState

Subtype of Str

Valid values:

=over

=item * C<quasi>

=item * C<full>

=back

Type of quotation environment. C<quasi> allows interpolation, C<full> doesn't.

=head2 SourceType

Subtype of Str

Valid values:

=over

=item * C<string>

=item * C<file>

=item * C<handle>

=back

Type of source that is read.

=head2 Location

Subtype of L<Dict|MooseX::Types::Structured/Dict>[source,Str,line,Int,char,Int,context,Str,offset,Int]

Record containing a position and context in the source.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<MooseX::Types>

=item * L<Moose::Manual::Types>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut