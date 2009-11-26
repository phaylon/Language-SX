use MooseX::Declare;

class Language::SX::Document::Keyword extends Language::SX::Document::Value {
    
    use Data::Dump              qw( pp );
    use MooseX::Types::Moose    qw( Bool );
    use Language::SX::Types;

    method compile (Language::SX::Inflator $inf, @) {

        return $inf->render_call(
            method  => 'make_keyword_constant',
            args    => { value => pp($self->value) },
        );
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Document::Keyword
Keyword constant value

@method compile
Compiles into a call to L<Language::SX::Inflator/make_keyword_constant>.

@description
This is the document item class for keyword constants.

=end fusion






=head1 NAME

Language::SX::Document::Keyword - Keyword constant value

=head1 INHERITANCE

=over 2

=item *

Language::SX::Document::Keyword

=over 2

=item *

L<Language::SX::Document::Value>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This is the document item class for keyword constants.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Language::SX::Document::Value/"location (required)"> attribute
inherited from L<Language::SX::Document::Value>.

=item * value (B<required>)

Initial value for the L<value|Language::SX::Document::Value/"value (required)"> attribute
inherited from L<Language::SX::Document::Value>.

=back

=head2 compile

    ->compile(Language::SX::Inflator $inf, @)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=back

=back

Compiles into a call to L<Language::SX::Inflator/make_keyword_constant>.

=head2 meta

Returns the meta object for C<Language::SX::Document::Keyword> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut