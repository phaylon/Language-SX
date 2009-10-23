use MooseX::Declare;

class Template::SX::Reader::Stream {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( Offset Scope );
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

    method content_line_count {
        my @lines = split /\n/, $self->content;
        return scalar @lines;
    }

    method content_rest_line_count {
        my @lines = split /\n/, $self->content_rest;
        return scalar @lines;
    }

    method current_line {

        return( 
            ($self->content_line_count - $self->content_rest_line_count) 
            + 1 
        );
    }

    method current_location {

        return +{
            source  => $self->source_name,
            line    => $self->current_line,
            char    => $self->current_char,
            context => $self->current_line_content,
            offset  => $self->offset,
        };
    }

    method current_char {

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
                \A
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
            ; :
        /, ',', '#');

        my $rx_join = sub { join ' ', map("(?! $_ )", '\s', map("\Q$_\E", @_)) };

        my $rx_na   = $rx_join->(@not_allowed);
        my $rx_beg  = $rx_join->(@not_allowed, 0..9);
        my $rx      = qr/ 
            (?: $rx_beg . ) 
            (?: $rx_na  . )* 
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
        ]x;

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
              " .*
        /x;

        if (defined( my $str = $self->try_regex($rx) )) {

            return [string => $str];
        }
    }
}
