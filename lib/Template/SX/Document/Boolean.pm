use MooseX::Declare;

class Template::SX::Document::Boolean extends Template::SX::Document::Value {
    
    use Data::Dump qw( pp );
    use MooseX::Types::Moose qw( Bool );
    use Template::SX::Types;

    my %ValueMap = (t => 1, true => 1, yes => 1, f => undef, false => undef, no => undef);

    method compile (Template::SX::Inflator $inf, @) {

        return $inf->render_call(
            method  => 'make_boolean_constant',
            args    => { value => pp($ValueMap{ $self->value }) },
        );
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Document::Boolean
Boolean constant value

@method compile
Compiles the value into a call to L<Template::SX::Inflator/make_boolean_constant>.

@description
This is the document item class for boolean constants.

=end fusion






=head1 NAME

Template::SX::Document::Boolean - Boolean constant value

=head1 INHERITANCE

=over 2

=item *

Template::SX::Document::Boolean

=over 2

=item *

L<Template::SX::Document::Value>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This is the document item class for boolean constants.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Template::SX::Document::Value/"location (required)"> attribute
inherited from L<Template::SX::Document::Value>.

=item * value (B<required>)

Initial value for the L<value|Template::SX::Document::Value/"value (required)"> attribute
inherited from L<Template::SX::Document::Value>.

=back

=head2 compile

    ->compile(Template::SX::Inflator $inf, @)

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=back

=back

Compiles the value into a call to L<Template::SX::Inflator/make_boolean_constant>.

=head2 meta

Returns the meta object for C<Template::SX::Document::Boolean> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut