use MooseX::Declare;

class Template::SX::Document::Quote {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );

    my %QuoteType = (
        q(`),   'quasiquote',
        q('),   'quote',
        q(,),   'unquote',
        q(,@),  'unquote-splicing',
    );

    method new_from_stream (ClassName $class: Template::SX::Document $doc, Template::SX::Reader::Stream $stream, Str $value, Location $loc) {

        require Template::SX::Document::Cell::Application;
        require Template::SX::Document::Bareword;

        my $contained_token = $stream->next_token;
        my $contained_node  = $doc->new_node_from_stream($stream, $contained_token);
        my $identifier_node = Template::SX::Document::Bareword->new(
            value       => $QuoteType{ $value },
            location    => $loc,
        );

        return Template::SX::Document::Cell::Application->new(
            nodes       => [$identifier_node, $contained_node],
            location    => $loc,
        );
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Library::Quoting
@license  Template::SX

@class Template::SX::Document::Quote
Quoting syntax element

@DESCRIPTION
This class is not usually used in its instantiated form. The L</new_from_stream> 
method will transform the input into a new cell containing the correct syntax element
invocation.

@method new
Instantiating this class makes no real sense. It exists in this form merely to be in
sync with the other document items.

@method new_from_stream
%param $value The literal value of the quotation syntax.
This method will transform the next available node in the C<$stram> into a quoted
expression of the form

    (quote <identifier> <node>)

where C<identifier> is either C<quote> for C<'>, C<quasiquote> for C<`>, C<unquote>
for C<,> and C<unquote-splicing> for C<,@>.

=end fusion






=head1 NAME

Template::SX::Document::Quote - Quoting syntax element

=head1 INHERITANCE

=over 2

=item *

Template::SX::Document::Quote

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This class is not usually used in its instantiated form. The L</new_from_stream> 
method will transform the input into a new cell containing the correct syntax element
invocation.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

Instantiating this class makes no real sense. It exists in this form merely to be in
sync with the other document items.

=head2 new_from_stream

    ->new_from_stream(
        ClassName $class:
        Template::SX::Document $doc,
        Template::SX::Reader::Stream $stream,
        Str $value,
        Location $loc
    )

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Document> C<$doc>

=item * L<Template::SX::Reader::Stream> C<$stream>

=item * Str C<$value>

The literal value of the quotation syntax.

=item * L<Location|Template::SX::Types/Location> C<$loc>

=back

=back

This method will transform the next available node in the C<$stram> into a quoted
expression of the form

    (quote <identifier> <node>)

where C<identifier> is either C<quote> for C<'>, C<quasiquote> for C<`>, C<unquote>
for C<,> and C<unquote-splicing> for C<,@>.

=head2 meta

Returns the meta object for C<Template::SX::Document::Quote> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Library::Quoting>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut