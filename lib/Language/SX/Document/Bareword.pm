use MooseX::Declare;

class Language::SX::Document::Bareword 
    extends Language::SX::Document::Value {

    use Data::Dump           qw( pp );
    use MooseX::Types::Moose qw( Str );
    use Language::SX::Types;

    has '+value' => (isa => Str);

    method is_dot { $self->value eq '.' }

    method compile_functional (Language::SX::Inflator $inf) {

        return $inf->render_call(
            method  => 'make_getter',
            args    => {
                name        => pp($inf->collect_lexical($self->value)),
                location    => pp($self->location),
            },
        );
    }

    method compile_structural (Language::SX::Inflator $inf) {

        return $inf->render_call(
            method  => 'make_object_builder',
            args    => {
                class       => pp('Language::SX::Runtime::Bareword'),
                arguments   => pp({ value => $self->value }),
                cached_by   => pp('value'),
#                arguments   => sprintf(
#                    '{ value => %s, cached_by => q(value) }', pp($self->value),
#                ),
            },
        );
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Runtime::Bareword
@license  Language::SX

@class Language::SX::Document::Bareword
Bareword constant value

@method compile_functional
Compiles the bareword in a functional scope to a call to L<Language::SX::Inflator/make_getter>
to fetch a variable from the environment.

@method compile_structural
Compiles the bareword in a structural scope to a call to L<Language::SX::Inflator/make_object_builder>
that creates a L<Language::SX::Runtime::Bareword>.

@method is_dot
True if the value of this bareword is C<.>.

@attr value
Same as in L<Language::SX::Document::Value|Language::SX::Document::Value/"value (required)"> but with 
a C<Str> constraint.

@description
This is the document item class for barewords. In structural scope a bareword will be transformed into
a runtime bareword, while a functional scope leads to a getter returning a variable value from the 
environment it was evaluated against.

=end fusion






=head1 NAME

Language::SX::Document::Bareword - Bareword constant value

=head1 INHERITANCE

=over 2

=item *

Language::SX::Document::Bareword

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

This is the document item class for barewords. In structural scope a bareword will be transformed into
a runtime bareword, while a functional scope leads to a getter returning a variable value from the 
environment it was evaluated against.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * location (B<required>)

Initial value for the L<location|Language::SX::Document::Value/"location (required)"> attribute
inherited from L<Language::SX::Document::Value>.

=item * value (B<required>)

Initial value for the L<value|/"value (required)"> attribute.

=back

=head2 compile_functional

    ->compile_functional(Language::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=back

=back

Compiles the bareword in a functional scope to a call to L<Language::SX::Inflator/make_getter>
to fetch a variable from the environment.

=head2 compile_structural

    ->compile_structural(Language::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * L<Language::SX::Inflator> C<$inf>

=back

=back

Compiles the bareword in a structural scope to a call to L<Language::SX::Inflator/make_object_builder>
that creates a L<Language::SX::Runtime::Bareword>.

=head2 is_dot

    ->is_dot(@)

=over

=back

True if the value of this bareword is C<.>.

=head2 value

Accessor for the L<value|/"value (required)"> attribute.

=head2 meta

Returns the meta object for C<Language::SX::Document::Bareword> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 value (required)

=over

=item * Type Constraint

Str

=item * Constructor Argument

C<value>

=item * Associated Methods

L<value|/value>

=back

Same as in L<Language::SX::Document::Value|Language::SX::Document::Value/"value (required)"> but with 
a C<Str> constraint.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Runtime::Bareword>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut