use MooseX::Declare;

class Template::SX::Library::ScopeHandling::Lambda 
    with Template::SX::Document::Locatable {

    use MooseX::Types::Moose qw( ArrayRef Object ClassName );
    use Template::SX::Types;

    has body => (
        is          => 'ro',
        isa         => ArrayRef[Object],
        required    => 1,
    );

    has signature => (
        is          => 'ro',
        isa         => Object,
        required    => 1,
    );

    has library => (
        is          => 'ro',
        isa         => Object,
        required    => 1,
        handles     => {
            _render => '_render_lambda_from_signature',
        },
    );

    method compile (Template::SX::Inflator $inf, @) {

        return $self->_render($inf, $self->signature, $self->body);
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Library::ScopeHandling
@license  Template::SX

@class Template::SX::Library::ScopeHandling::Lambda
Internal lambda generation

@DESCRIPTION
This is an internal class used to create functions in some corner cases.

@method compile
Compiles the function.

@attr body
All expressions that are contained in the body.

@attr library
Library object to use for rendering the function.

@attr signature
Function signature structure.

=end fusion






=head1 NAME

Template::SX::Library::ScopeHandling::Lambda - Internal lambda generation

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::ScopeHandling::Lambda

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<Template::SX::Document::Locatable>

=back

=head1 DESCRIPTION

This is an internal class used to create functions in some corner cases.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * body (B<required>)

Initial value for the L<body|/"body (required)"> attribute.

=item * library (B<required>)

Initial value for the L<library|/"library (required)"> attribute.

=item * location (B<required>)

Initial value for the L<location|Template::SX::Document::Locatable/"location (required)"> attribute
composed in by L<Template::SX::Document::Locatable>.

=item * signature (B<required>)

Initial value for the L<signature|/"signature (required)"> attribute.

=back

=head2 body

Reader for the L<body|/"body (required)"> attribute.

=head2 compile

    ->compile(Template::SX::Inflator $inf, @)

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=back

=back

Compiles the function.

=head2 library

Reader for the L<library|/"library (required)"> attribute.

=head2 signature

Reader for the L<signature|/"signature (required)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Library::ScopeHandling::Lambda> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 body (required)

=over

=item * Type Constraint

ArrayRef[Object]

=item * Constructor Argument

C<body>

=item * Associated Methods

L<body|/body>

=back

All expressions that are contained in the body.

=head2 library (required)

=over

=item * Type Constraint

Object

=item * Constructor Argument

C<library>

=item * Associated Methods

L<library|/library>

=back

Library object to use for rendering the function.

=head2 signature (required)

=over

=item * Type Constraint

Object

=item * Constructor Argument

C<signature>

=item * Associated Methods

L<signature|/signature>

=back

Function signature structure.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Library::ScopeHandling>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut