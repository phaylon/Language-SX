use MooseX::Declare;

class Template::SX::Document::String::Constant 
    extends Template::SX::Document::Value {

    use Data::Dump           qw( pp );
    use Template::SX::Types  qw( Scope );

    method compile (Template::SX::Inflator $inf, Scope $scope) {

        return $inf->render_call(
            method  => 'make_constant',
            args    => {
                value   => pp($self->value),
            },
        );
    }

    method clean_end () {

        my $val = $self->value;
        $val =~ s/ \s* \Z //xs;
        $self->value($val);
    }

    method clean_front () {

        my $val = $self->value;
        $val =~ s/ \A \s* //xs;
        $self->value($val);
    }

    method clean_lines () {

        my $val = $self->value;
        $val =~ s/ (?: ^ \s* | \s* $ ) //gxm;
        $self->value($val);
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Document::String
@license  Template::SX

@class Template::SX::Document::String::Constant
Purely constant strings

@description
While L<Template::SX::Document::String> represents a string item with interpolated
parts, this class is specific to constant and pure string values only.

@method clean_end
Special case for C<» ... «>. Removes all trailing spaces from the string.

@method clean_front
Special case for C<» ... «>. Removes all leading spaces from the string.

@method clean_lines
Special case for C<» ... «>. Removes all leading and trailing spaces from each line in the string.

@method compile
Compiles to a call to L<Template::SX::Inflator/make_constant>.

=end fusion






=head1 NAME

Template::SX::Document::String::Constant - Purely constant strings

=head1 INHERITANCE

=over 2

=item *

Template::SX::Document::String::Constant

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

While L<Template::SX::Document::String> represents a string item with interpolated
parts, this class is specific to constant and pure string values only.

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

=head2 clean_end

    ->clean_end()

=over

=back

Special case for C<» ... «>. Removes all trailing spaces from the string.

=head2 clean_front

    ->clean_front()

=over

=back

Special case for C<» ... «>. Removes all leading spaces from the string.

=head2 clean_lines

    ->clean_lines()

=over

=back

Special case for C<» ... «>. Removes all leading and trailing spaces from each line in the string.

=head2 compile

    ->compile(Template::SX::Inflator $inf, Scope $scope)

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=item * L<Scope|Template::SX::Types/Scope> C<$scope>

=back

=back

Compiles to a call to L<Template::SX::Inflator/make_constant>.

=head2 meta

Returns the meta object for C<Template::SX::Document::String::Constant> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Document::String>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut