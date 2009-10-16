use MooseX::Declare;

class Template::SX::Reader::Stream {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( Offset Scope );
    use MooseX::Types::Moose    qw( Str Int );

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
#        warn "skipping spaces";

        if ($self->content_rest =~ /^(\s+)/) {
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
            bareword
        );
    }

    method try_regex (RegexpRef $rx, Bool :$bare) {

        my $full_rx = $bare ? qr/^($rx)/ : qr/
            ^
            ($rx)
            (?:
                (?= \) | \] | \} | \s )
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

        for my $type ($self->token_precedence) {

            my $method = "_parse_${type}";

            if (my $found = $self->$method) {

                $self->skip_spaces;

                return $found;
            }
        }

        # FIXME throw exception instead
        die "Unable to parse: " . $self->content_rest;
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

    method _parse_bareword () {

        my @not_allowed = (qw/
            { } ( ) [ ]
             . ` @ %
        /, ',');

        my $rx_na = join ' ', map("(?! $_ )", '\s', map("\Q$_\E", @not_allowed));
        my $rx = qr/ (?: $rx_na . )+ /x;

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

    method _parse_numbers () {

        my $rx_num = qr/
            [+-]?
            [0-9]
            (?:
              [0-9_]*
              [0-9]
            )?
        /x;

        my $rx = qr/
            $rx_num
            (?:
              \.
              $rx_num
            )?
        /x;

        if (defined( my $num = $self->try_regex($rx) )) {

            $num =~ s/_//g;
            return [number => $num];
        }
    }

    method _parse_strings () {

        my $rx = qr/
              (?: " .*? (?<! \\ ) " )
            | (?: ' .*? (?<! \\ ) ' )
        /x;

        if (defined( my $str = $self->try_regex($rx) )) {

            return [string => $str];
        }
    }
}
