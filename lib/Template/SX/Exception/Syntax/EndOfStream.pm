use MooseX::Declare;

class Template::SX::Exception::Syntax::EndOfStream 
    extends Template::SX::Exception::Syntax {

}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Exception::Syntax::EndOfStream
Unexpected end of stream

@description
This exception will be raised when the stream ended before all cells were closed. This
is mostly useful for REPL implementations to figure out that the previous expression
was incomplete.

=end fusion






=head1 NAME

Template::SX::Exception::Syntax::EndOfStream - Unexpected end of stream

=head1 INHERITANCE

=over 2

=item *

Template::SX::Exception::Syntax::EndOfStream

=over 2

=item *

L<Template::SX::Exception::Syntax>

=over 2

=item *

L<Template::SX::Exception>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=back

=head1 DESCRIPTION

This exception will be raised when the stream ended before all cells were closed. This
is mostly useful for REPL implementations to figure out that the previous expression
was incomplete.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Template::SX::Exception/"location (required)"> attribute
inherited from L<Template::SX::Exception>.

=item * message (B<required>)

Initial value for the L<message|Template::SX::Exception/"message (required)"> attribute
inherited from L<Template::SX::Exception>.

=back

=head2 meta

Returns the meta object for C<Template::SX::Exception::Syntax::EndOfStream> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut