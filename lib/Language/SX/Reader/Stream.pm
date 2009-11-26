use MooseX::Declare;
use utf8;

class Language::SX::Reader::Stream {

    use Language::SX::Constants qw( :all );
    use Language::SX::Types     qw( Offset Scope );
    use MooseX::Types::Moose    qw( Str Int );

    Class::MOP::load_class(E_SYNTAX);

    has content => (
        traits      => [qw( String )],
        is          => 'ro',
        isa         => Str,
        required    => 1,
        handles     => {
            content_length  => 'length',
            content_substr  => 'substr',
        },
    );

    has offset => (
        traits      => [qw( Counter )],
        is          => 'rw',
        isa         => Offset,
        required    => 1,
        default     => 0,
        handles     => {
            skip    => 'inc',
            reset   => 'reset',
        },
    );

    my $AnonSource = 0;

    has source_name => (
        is          => 'rw',
        isa         => Str,
        required    => 1,
        default     => sub { sprintf '(SX:%d)', $AnonSource++ },
    );

    method substream (Int :$offset) {

        return $self->meta->clone_object($self,
            offset      => $offset,
            content     => $self->content,
            source_name => $self->source_name,
        );
    }

    method set_from_stream (Object :$stream) {

        $self->offset( $stream->offset );
    }

    method content_line_count () {
        my @lines = split /\n/, $self->content;
        return scalar @lines;
    }

    method content_rest_line_count () {
        my @lines = split /\n/, $self->content_rest;
        return scalar @lines;
    }

    method current_line () {

        return( 
            ($self->content_line_count - $self->content_rest_line_count) 
            + 1 
        );
    }

    method current_location () {

        return +{
            source  => $self->source_name,
            line    => $self->current_line,
            char    => $self->current_char,
            context => $self->current_line_content,
            offset  => $self->offset,
        };
    }

    method current_char () {

        my $last_nl = rindex $self->content, "\n", $self->offset;

        if ($last_nl < 0) {
            return $self->offset + 1;
        }
        else {
            return( ($self->offset - $last_nl) + 1 );
        }
    }

    method current_line_content () {

        my $line = ( ( split /\n/, $self->content )[ $self->current_line - 1 ] );
        chomp $line;

        return $line;
    }

    method content_rest () { 
        return $self->content_substr($self->offset);
    }

    method content_rest_length () {
        return $self->content_length - $self->offset;
    }

    method end_of_stream () {
        return $self->content_rest_length == 0;
    }

    method skip_spaces () {

        my $rx = qr/
            (?:
                \s*
                (?:
                    ;
                    .*?
                    $
                )?
            )
        /xm;

        if ($self->content_rest =~ /\A ($rx+) /x) {
            $self->skip(length $1);
        }

        return 1;
    }

    method token_precedence () {

        return qw(
            quoting
            numbers
            strings
            cell
            boolean
            keyword
            regex
            bareword
        );
    }

    method try_regex (RegexpRef $rx, Bool :$bare) {

        my $full_rx = $bare ? qr/^($rx)/ : qr/
            ^
            ($rx)
            (?:
                (?= \) | \] | \} | \s | ; )
              | $
            )
        /x;

        if ($self->content_rest =~ $full_rx) {

            $self->skip(length $1);
            return $1;
        }

        return undef;
    }

    method next_token () {

        $self->skip_spaces;

        if ($self->end_of_stream) {

            $self->reset;
            return undef;
        }

        my $location = $self->current_location;

        for my $type ($self->token_precedence) {

            my $method = "_parse_${type}";

            if (my $found = $self->$method) {

 #               $self->skip_spaces;

                return [ @$found, $location ];
            }
        }

        E_SYNTAX->throw(
            location    => $location,
            message     => 'unable to parse rest of stream',
        );
    }

    method to_tokens () {

        my @parsed;

        while (my $token = $self->next_token) {

            push @parsed, $token;
        }

        return @parsed;
    }

    my %CellType = (
        '(',    'cell_open',
        ')',    'cell_close',
        '[',    'cell_open',
        ']',    'cell_close',
        '{',    'cell_open',
        '}',    'cell_close',
    );

    method _parse_cell () {

        my $rx = join '|', map { qr/\Q$_\E/ } keys %CellType;

        if (defined( my $v = $self->try_regex(qr/$rx/x, bare => 1) )) {

            return [$CellType{ $v }, $v];
        }

        return undef;
    }

    method _parse_boolean () {

        if (defined( my $bool = $self->try_regex(qr/ \# (?: t | f | yes | no | true | false ) /x) )) {
            $bool =~ s/\A\#//;
            return [boolean => $bool];
        }

        return undef;
    }

    method _parse_keyword () {

        my $rx_word = qr/[a-z_-]/i;
        my $rx_full = qr/$rx_word (?: $rx_word | [0-9] )*/x;
        my $rx      = qr/
            (?: : $rx_full )
              |
            (?: $rx_full : )
        /x;

        if (defined( my $keyword = $self->try_regex($rx) )) {
            $keyword =~ s/(\A:|:\Z)//g;
            $keyword =~ s/-/_/g;
            return [keyword => $keyword];
        }

        return undef;
    }

    method _parse_bareword () {

        my @not_allowed = (qw/
            { } ( ) [ ]
            ` " ' 
            @ % 
            ; 
        /, ',', '#');

        my $rx_join = sub { join ' ', map("(?! $_ )", '\s', map("\Q$_\E", @_)) };

        my $rx_na   = $rx_join->(@not_allowed);
        my $rx_beg  = $rx_join->(@not_allowed, 0..9);
        my $rx      = qr/
            (?! : )
            (?:
              (?:
                (?: $rx_beg . ) 
                (?: $rx_na  . )* 
              )
                |
              \#
            )
            (?<! : )
        /x;

        my $rx_old = qr/
            [a-z_]
            (?:
              [a-z0-9_-]*
              [a-z0-9_]
            )?
        /xi;

        if (defined( my $word = $self->try_regex(qr/$rx/) )) {
            return [bareword => $word];
        }

        return undef;
    }

    my %QuoteType = (
        q('),   'quote',
        q(`),   'quote',
        q(,@),  'unquote',
        q(,),   'unquote',
    );

    method _parse_quoting () {

        my $rx = join '|',  keys %QuoteType;

        if (defined( my $sign = $self->try_regex(qr/$rx/, bare => 1) )) {
            return [$QuoteType{ $sign }, $sign];
        }

        return undef;
    }

    method _parse_regex () {

        my $rx_mod = qr/ (?: [a-z]* (?: - [a-z]+ )? ) /xi;
        my $rx = qr[
            rx
            (?:
                (?: / .*? (?<!\\) / $rx_mod )
                  |
                (?: \( .*? (?<!\\) \) $rx_mod )
                  |
                (?: \{ .*? (?<!\\) \} $rx_mod )
            )
        ]xs;

        if (defined( my $regex = $self->try_regex(qr/$rx/, bare => 1) )) {
            return [regex => $regex];
        }

        return undef;
    }

    method _parse_numbers () {

        my $rx_num = qr/
            [0-9]
            (?:
              [0-9_]*
              [0-9]
            )?
        /x;

        my $rx = qr/
            [+-]?
            (?:
              (?:               # 5 -5
                $rx_num
                (?:             # 5.5 -5.5
                  \.
                  $rx_num
                )?
              )
              |
              (?:               # .5 -.5
                \.
                $rx_num
              )
            )
        /x;

        if (defined( my $num = $self->try_regex($rx) )) {

            $num =~ s/_//g;
            return [number => $num];
        }
    }

    method _parse_strings () {

        my $rx = qr/
              (?: " | » ) .*
        /xs;

        if (defined( my $str = $self->try_regex($rx) )) {

            return [string => $str];
        }
    }
}

1;

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Reader
@license  Language::SX

@class Language::SX::Reader::Stream
Transform strings to token streams

@method content_length
Returns the length of the whole content string.

@method content_line_count
Returns the number of lines in the content string.

@method content_rest
Rest of the content beyond the L</offset>.

@method content_rest_length
Length of the L</content_rest>.

@method content_rest_line_count
Number of lines left in the rest of the content.

@method current_char
The current character in the current line.

@method current_line
The current line.

@method current_line_content
Content of the current line.

@method current_location
Builds a L<Language::SX::Types/Location>.

@method end_of_stream
True if we hit the end of the stream.

@method next_token
Return the next token in the stream.

@method offset
The current offset in the content string.

@method reset
Reset the offset.

@method set_from_stream
%param :$stream The stream with the value to transfer.
Takes values (currently only the offset) from the passed stream and sets it in the
current instance.

@method skip
Skip a number of characters.

@method skip_spaces
Skip all possible spaces in the stream.

@method substream
%param :$offset Where the new substream starts.
Create a new stream that starts at the passed in C<$offset>.

@method to_tokens
B<Deprecated!> Builds a list of all tokens.

@method token_precedence
Returns the order of the token types to try.

@method try_regex
%param $rx The regular expression to try.
%param :$bare Don't enforce specialised token ends.

@attr content
The content string.

@attr offset
The offset in the content string.

@attr source_name
A descriptive name identifying the source. For example a filename.

=end fusion






=head1 NAME

Language::SX::Reader::Stream - Transform strings to token streams

=head1 INHERITANCE

=over 2

=item *

Language::SX::Reader::Stream

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * content (B<required>)

Initial value for the L<content|/"content (required)"> attribute.

=item * offset (B<required>)

Initial value for the L<offset|/"offset (required)"> attribute.

=item * source_name (optional)

Initial value for the L<source_name|/"source_name (required)"> attribute.

=back

=head2 content

Reader for the L<content|/"content (required)"> attribute.

=head2 content_length

Delegation to a generated L<length|Moose::Meta::Attribute::Native::MethodProvider::String/length> method for the L<content|/content (required)> attribute.

Returns the length of the whole content string.

=head2 content_line_count

    ->content_line_count()

=over

=back

Returns the number of lines in the content string.

=head2 content_rest

    ->content_rest()

=over

=back

Rest of the content beyond the L</offset>.

=head2 content_rest_length

    ->content_rest_length()

=over

=back

Length of the L</content_rest>.

=head2 content_rest_line_count

    ->content_rest_line_count()

=over

=back

Number of lines left in the rest of the content.

=head2 content_substr

Delegation to a generated L<substr|Moose::Meta::Attribute::Native::MethodProvider::String/substr> method for the L<content|/content (required)> attribute.

=head2 current_char

    ->current_char()

=over

=back

The current character in the current line.

=head2 current_line

    ->current_line()

=over

=back

The current line.

=head2 current_line_content

    ->current_line_content()

=over

=back

Content of the current line.

=head2 current_location

    ->current_location()

=over

=back

Builds a L<Language::SX::Types/Location>.

=head2 end_of_stream

    ->end_of_stream()

=over

=back

True if we hit the end of the stream.

=head2 next_token

    ->next_token()

=over

=back

Return the next token in the stream.

=head2 offset

Accessor for the L<offset|/"offset (required)"> attribute.

The current offset in the content string.

=head2 reset

Delegation to a generated L<reset|Moose::Meta::Attribute::Native::MethodProvider::Counter/reset> method for the L<offset|/offset (required)> attribute.

Reset the offset.

=head2 set_from_stream

    ->set_from_stream(Object :$stream)

=over

=item * Named Parameters:

=over

=item * Object C<:$stream> (optional)

The stream with the value to transfer.

=back

=back

Takes values (currently only the offset) from the passed stream and sets it in the
current instance.

=head2 skip

Delegation to a generated L<inc|Moose::Meta::Attribute::Native::MethodProvider::Counter/inc> method for the L<offset|/offset (required)> attribute.

Skip a number of characters.

=head2 skip_spaces

    ->skip_spaces()

=over

=back

Skip all possible spaces in the stream.

=head2 source_name

Accessor for the L<source_name|/"source_name (required)"> attribute.

=head2 substream

    ->substream(Int :$offset)

=over

=item * Named Parameters:

=over

=item * Int C<:$offset> (optional)

Where the new substream starts.

=back

=back

Create a new stream that starts at the passed in C<$offset>.

=head2 to_tokens

    ->to_tokens()

=over

=back

B<Deprecated!> Builds a list of all tokens.

=head2 token_precedence

    ->token_precedence()

=over

=back

Returns the order of the token types to try.

=head2 try_regex

    ->try_regex(RegexpRef $rx, Bool :$bare)

=over

=item * Positional Parameters:

=over

=item * RegexpRef C<$rx>

The regular expression to try.

=back

=item * Named Parameters:

=over

=item * Bool C<:$bare> (optional)

Don't enforce specialised token ends.

=back

=back

=head2 meta

Returns the meta object for C<Language::SX::Reader::Stream> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 content (required)

=over

=item * Type Constraint

Str

=item * Default

C<>

=item * Constructor Argument

C<content>

=item * Associated Methods

L<content|/content>, L<content_length|/content_length>, L<content_substr|/content_substr>

=back

The content string.

=head2 offset (required)

=over

=item * Type Constraint

L<Offset|Language::SX::Types/Offset>

=item * Default

C<0>

=item * Constructor Argument

C<offset>

=item * Associated Methods

L<offset|/offset>, L<reset|/reset>, L<skip|/skip>

=back

The offset in the content string.

=head2 source_name (required)

=over

=item * Type Constraint

Str

=item * Default

Built during runtime.

=item * Constructor Argument

C<source_name>

=item * Associated Methods

L<source_name|/source_name>

=back

A descriptive name identifying the source. For example a filename.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Reader>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut