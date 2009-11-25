use MooseX::Declare;

class Template::SX::Library::Data extends Template::SX::Library::Group {
    use MooseX::ClassAttribute;
    use CLASS;

    class_has '+sublibraries';

    CLASS->add_sublibrary($_->new) for map { Class::MOP::load_class($_); $_ } qw(
        Template::SX::Library::Data::Common
        Template::SX::Library::Data::Functions
        Template::SX::Library::Data::Hashes
        Template::SX::Library::Data::Lists
        Template::SX::Library::Data::Numbers
        Template::SX::Library::Data::Objects
        Template::SX::Library::Data::Pairs
        Template::SX::Library::Data::Regex
        Template::SX::Library::Data::Strings
    );
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@license  Template::Sx

@class Template::SX::Library::Data
Data manipulation library group

@description
This library group contains all libraries related to data manipulation.
This group contains the following libraries:

=over

=item * L<Template::SX::Library::Data::Common>

Functionality that is common to or can be applied to more than one type of data.

=item * L<Template::SX::Library::Data::Functions>

Function manipulation.

=item * L<Template::SX::Library::Data::Hashes>

Hash creation, manipulation and access.

=item * L<Template::SX::Library::Data::Lists>

List creation, manipulation and access.

=item * L<Template::SX::Library::Data::Numbers>

Number manipulation and mathematics.

=item * L<Template::SX::Library::Data::Objects>

Object manipulation and inrospection.

=item * L<Template::SX::Library::Data::Pairs>

Pair manipulation and transformation.

=item * L<Template::SX::Library::Data::Regex>

Regular expression construction and matching.

=item * L<Template::SX::Library::Data::Strings>

String manipulation and creation.

=back

=end fusion






=head1 NAME

Template::SX::Library::Data - Data manipulation library group

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Data

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

This library group contains all libraries related to data manipulation.
This group contains the following libraries:

=over

=item * L<Template::SX::Library::Data::Common>

Functionality that is common to or can be applied to more than one type of data.

=item * L<Template::SX::Library::Data::Functions>

Function manipulation.

=item * L<Template::SX::Library::Data::Hashes>

Hash creation, manipulation and access.

=item * L<Template::SX::Library::Data::Lists>

List creation, manipulation and access.

=item * L<Template::SX::Library::Data::Numbers>

Number manipulation and mathematics.

=item * L<Template::SX::Library::Data::Objects>

Object manipulation and inrospection.

=item * L<Template::SX::Library::Data::Pairs>

Pair manipulation and transformation.

=item * L<Template::SX::Library::Data::Regex>

Regular expression construction and matching.

=item * L<Template::SX::Library::Data::Strings>

String manipulation and creation.

=back

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 meta

Returns the meta object for C<Template::SX::Library::Data> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::Sx> for information about license and copyright.

=cut