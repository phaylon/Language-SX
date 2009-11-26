use MooseX::Declare;

class Language::SX::Library::Data extends Language::SX::Library::Group {
    use MooseX::ClassAttribute;
    use CLASS;

    class_has '+sublibraries';

    CLASS->add_sublibrary($_->new) for map { Class::MOP::load_class($_); $_ } qw(
        Language::SX::Library::Data::Common
        Language::SX::Library::Data::Functions
        Language::SX::Library::Data::Hashes
        Language::SX::Library::Data::Lists
        Language::SX::Library::Data::Numbers
        Language::SX::Library::Data::Objects
        Language::SX::Library::Data::Pairs
        Language::SX::Library::Data::Regex
        Language::SX::Library::Data::Strings
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@license  Template::Sx

@class Language::SX::Library::Data
Data manipulation library group

@description
This library group contains all libraries related to data manipulation.
This group contains the following libraries:

=over

=item * L<Language::SX::Library::Data::Common>

Functionality that is common to or can be applied to more than one type of data.

=item * L<Language::SX::Library::Data::Functions>

Function manipulation.

=item * L<Language::SX::Library::Data::Hashes>

Hash creation, manipulation and access.

=item * L<Language::SX::Library::Data::Lists>

List creation, manipulation and access.

=item * L<Language::SX::Library::Data::Numbers>

Number manipulation and mathematics.

=item * L<Language::SX::Library::Data::Objects>

Object manipulation and inrospection.

=item * L<Language::SX::Library::Data::Pairs>

Pair manipulation and transformation.

=item * L<Language::SX::Library::Data::Regex>

Regular expression construction and matching.

=item * L<Language::SX::Library::Data::Strings>

String manipulation and creation.

=back

=end fusion






=head1 NAME

Language::SX::Library::Data - Data manipulation library group

=head1 INHERITANCE

=over 2

=item *

Language::SX::Library::Data

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

This library group contains all libraries related to data manipulation.
This group contains the following libraries:

=over

=item * L<Language::SX::Library::Data::Common>

Functionality that is common to or can be applied to more than one type of data.

=item * L<Language::SX::Library::Data::Functions>

Function manipulation.

=item * L<Language::SX::Library::Data::Hashes>

Hash creation, manipulation and access.

=item * L<Language::SX::Library::Data::Lists>

List creation, manipulation and access.

=item * L<Language::SX::Library::Data::Numbers>

Number manipulation and mathematics.

=item * L<Language::SX::Library::Data::Objects>

Object manipulation and inrospection.

=item * L<Language::SX::Library::Data::Pairs>

Pair manipulation and transformation.

=item * L<Language::SX::Library::Data::Regex>

Regular expression construction and matching.

=item * L<Language::SX::Library::Data::Strings>

String manipulation and creation.

=back

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Language::SX::Library::Data> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::Sx> for information about license and copyright.

=cut