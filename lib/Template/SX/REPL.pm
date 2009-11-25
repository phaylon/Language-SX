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

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Term::ReadLine::Zoid
@license  Template::SX

@class Template::SX::REPL
Reads, evaluates and prints L<Template::SX> expressions in a loop

@method complete
Currently inactive method.

@method find_barewords_in_string
Currently inactive method.

@method run
Runs the script code.

@method save_session
%param $session List of entries to save.
%param $target  Filename of the saved session.
Saves the session in a file.

@attr sx
The L<Template::SX> instance evaluating the expressions.

@DESCRIPTION
This module contains functionality for a L<Template::SX> REPL. A command-line interpreter
to play around in.

=end fusion






=head1 NAME

Template::SX::REPL - Reads, evaluates and prints L<Template::SX> expressions in a loop

=head1 INHERITANCE

=over 2

=item *

Template::SX::REPL

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This module contains functionality for a L<Template::SX> REPL. A command-line interpreter
to play around in.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * sx (optional)

Initial value for the L<sx|/"sx (required)"> attribute.

=back

=head2 clear_sx

Clearer for the L<sx|/"sx (required)"> attribute.

=head2 complete

    ->complete(
        ArrayRef[
            Str
        ] $possible,
        Str $word,
        Str $buffer,
        Int $start
    )

=over

=item * Positional Parameters:

=over

=item * ArrayRef[Str] C<$possible>

=item * Str C<$word>

=item * Str C<$buffer>

=item * Int C<$start>

=back

=back

Currently inactive method.

=head2 find_barewords_in_string

    ->find_barewords_in_string(Str $string, Str $not)

=over

=item * Positional Parameters:

=over

=item * Str C<$string>

=item * Str C<$not>

=back

=back

Currently inactive method.

=head2 has_sx

Predicate for the L<sx|/"sx (required)"> attribute.

=head2 run

    ->run()

=over

=back

Runs the script code.

=head2 save_session

    ->save_session(ArrayRef[Str] $session, File $target does coerce)

=over

=item * Positional Parameters:

=over

=item * ArrayRef[Str] C<$session>

List of entries to save.

=item * L<File|MooseX::Types::Path::Class/File> C<$target>

Filename of the saved session.

=back

=back

Saves the session in a file.

=head2 meta

Returns the meta object for C<Template::SX::REPL> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 sx (required)

=over

=item * Type Constraint

L<Template::SX>

=item * Default

Built lazily during runtime.

=item * Constructor Argument

C<sx>

=item * Associated Methods

L<has_sx|/has_sx>, L<clear_sx|/clear_sx>

=back

The L<Template::SX> instance evaluating the expressions.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Term::ReadLine::Zoid>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut