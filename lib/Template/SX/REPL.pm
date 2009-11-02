use MooseX::Declare;

class Template::SX::REPL {
    use CLASS;

    use TryCatch;
    use Term::ReadLine::Zoid;
    use Template::SX;
    use Template::SX::Types;
    use MooseX::Types::Moose        qw( Object );
    use Data::Dump                  qw( pp );
    use MooseX::Types::Path::Class  qw( File );

    has sx => (
        isa         => 'Template::SX',
        required    => 1,
        lazy_build  => 1,
        handles     => {
            _run_expression     => 'run',
            _create_stream      => '_stream_from_string',
            _all_functions      => 'all_function_names',
            _all_syntaxes       => 'all_syntax_names',
            _version            => 'VERSION',
        },
    );

    method _build_sx { Template::SX->new }

    method complete (ArrayRef[Str] $possible, Str $word, Str $buffer, Int $start) {

        return
            sort { length($a) <=> length($b) }
            grep { $_ =~ /\A \Q$word\E/x }
                @$possible, $self->find_barewords_in_string($buffer, $word);
    }

    method find_barewords_in_string (Str $string, Str $not) {

        my @barewords;
        
        try {
            my $stream = $self->_create_stream($string);
            @barewords = grep { $_ ne $not } map { $_->[1] } grep { $_->[0] eq 'bareword' } $stream->to_tokens;
        }
        catch (Any $e) { warn "ERR $e"; }

        return @barewords;
    }

    method save_session (ArrayRef[Str] $session, File $target does coerce) {

        my $fh = $target->openw;
        print $fh join("\n", @$session);
        printf "saved: %s\n", $target->absolute;
    }

    method run () {

        my @committed;
        my $term    = Term::ReadLine::Zoid->new(CLASS);
        my $count   = 1;
        my $vars    = { quit => sub { exit }, save => sub { $self->save_session(\@committed, @_) }};
        my @globals = ($self->_all_functions, $self->_all_syntaxes);
        my @buffer;
        my $indent;
        my $last;

        $term->Attribs->{default_mode}  = 'multiline';
        $term->Attribs->{autohistory}   = 1;
        $term->Attribs->{PS2}           = ' > ';
        $term->Attribs->{RPS1}          = "; run $count";
        $term->Attribs->{comment_begin} = undef;

        $term->Attribs->{completion_function} 
            = sub { $self->complete([keys(%$vars), @globals], @_) };

        $term->bindkey('page_up',   sub { $term->previous_history },    'multiline');
        $term->bindkey('page_down', sub { $term->next_history },        'multiline');

        printf "REPL for %s version %s\n", 'Template::SX', $self->_version;
        print  "send input:             (ctrl-d)  cancel input: (ctrl-c)\n";
        print  "previous history entry: (pg-up)   next entry:   (pg-down)\n";
        print  "\n";

        while (defined( my $line = $term->readline('+> ') )) {

            try {
                $vars->{ '$' } = $last;

                my $code   = join("\n", @buffer, $line);
                my $result = pp($last = $self->_run_expression(
                    string      => $code, 
                    source_name => sprintf('(sx-repl:%d)', $count++),
                    vars        => $vars,
                    persist     => 1,
                ));

                chomp $result;
                printf "result: %s\n\n", $result;
                push @committed, $code;
            }
            catch (Any $e) {
                print $e;
            }
        
            $term->Attribs->{RPS1} = "; run $count";
        }
    }
}
