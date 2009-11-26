use MooseX::Declare;

class Language::SX::Library::Core extends Language::SX::Library::Group {
    use MooseX::ClassAttribute;
    use CLASS;

    class_has '+sublibraries';

    CLASS->add_sublibrary($_->new) for map { Class::MOP::load_class($_); $_ } qw(
        Language::SX::Library::Branching
        Language::SX::Library::Data
        Language::SX::Library::Inserts
        Language::SX::Library::Operators
        Language::SX::Library::Quoting
        Language::SX::Library::ScopeHandling
        Language::SX::Library::Types
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Language::SX

@class Language::SX::Library::Core
Core library group

@description
This bundle contains all core functionality. This library will be loaded by L<Template:SX>
unless an other set is explicitely specified.

This group contains the following libraries:

=over

=item * L<Language::SX::Library::Branching>

Branching and conditionals.

=item * L<Language::SX::Library::Data>

Data access and manipulation.

=item * L<Language::SX::Library::Inserts>

Reusing other documents.

=item * L<Language::SX::Library::Operators>

General operators.

=item * L<Language::SX::Library::Quoting>

Quoting and building data structures by syntax.

=item * L<Language::SX::Library::ScopeHandling>

Variable definition, scoping and manipulation.

=item * L<Language::SX::Library::Types>

Type creation and handling.

=back

=end fusion






=head1 NAME

Language::SX::Library::Core - Core library group

=head1 INHERITANCE

=over 2

=item *

Language::SX::Library::Core

=over 2

=item *

L<Language::SX::Library::Group>

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

=item * L<Language::SX::Library::Branching>

Branching and conditionals.

=item * L<Language::SX::Library::Data>

Data access and manipulation.

=item * L<Language::SX::Library::Inserts>

Reusing other documents.

=item * L<Language::SX::Library::Operators>

General operators.

=item * L<Language::SX::Library::Quoting>

Quoting and building data structures by syntax.

=item * L<Language::SX::Library::ScopeHandling>

Variable definition, scoping and manipulation.

=item * L<Language::SX::Library::Types>

Type creation and handling.

=back

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Language::SX::Library::Core> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut