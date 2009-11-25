use MooseX::Declare;

class Template::SX::Library::Core extends Template::SX::Library::Group {
    use MooseX::ClassAttribute;
    use CLASS;

    class_has '+sublibraries';

    CLASS->add_sublibrary($_->new) for map { Class::MOP::load_class($_); $_ } qw(
        Template::SX::Library::Branching
        Template::SX::Library::Data
        Template::SX::Library::Inserts
        Template::SX::Library::Operators
        Template::SX::Library::Quoting
        Template::SX::Library::ScopeHandling
        Template::SX::Library::Types
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::SX

@class Template::SX::Library::Core
Core library group

@description
This bundle contains all core functionality. This library will be loaded by L<Template:SX>
unless an other set is explicitely specified.

This group contains the following libraries:

=over

=item * L<Template::SX::Library::Branching>

Branching and conditionals.

=item * L<Template::SX::Library::Data>

Data access and manipulation.

=item * L<Template::SX::Library::Inserts>

Reusing other documents.

=item * L<Template::SX::Library::Operators>

General operators.

=item * L<Template::SX::Library::Quoting>

Quoting and building data structures by syntax.

=item * L<Template::SX::Library::ScopeHandling>

Variable definition, scoping and manipulation.

=item * L<Template::SX::Library::Types>

Type creation and handling.

=back

=end fusion






=head1 NAME

Template::SX::Library::Core - Core library group

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Core

=over 2

=item *

L<Template::SX::Library::Group>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This bundle contains all core functionality. This library will be loaded by L<Template:SX>
unless an other set is explicitely specified.

This group contains the following libraries:

=over

=item * L<Template::SX::Library::Branching>

Branching and conditionals.

=item * L<Template::SX::Library::Data>

Data access and manipulation.

=item * L<Template::SX::Library::Inserts>

Reusing other documents.

=item * L<Template::SX::Library::Operators>

General operators.

=item * L<Template::SX::Library::Quoting>

Quoting and building data structures by syntax.

=item * L<Template::SX::Library::ScopeHandling>

Variable definition, scoping and manipulation.

=item * L<Template::SX::Library::Types>

Type creation and handling.

=back

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Template::SX::Library::Core> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut