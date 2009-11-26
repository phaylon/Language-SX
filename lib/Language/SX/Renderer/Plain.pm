use MooseX::Declare;

class Language::SX::Renderer::Plain with Language::SX::Renderer::TagBased {

    use HTML::Entities qw( encode_entities );

    sub _build_element_formatter {

        return sub {
            my ($name, $attrs, @contents) = @_;

            unless (@contents) {

                return sprintf('<%s%s />',
                    $name,
                  ( @$attrs ? (join '', map " $_", @$attrs) : '' ),
                );
            }

            return sprintf('<%s%s>%s</%s>',
                $name,
              ( @$attrs ? (join '', map " $_", @$attrs) : '' ),
                join(' ', @contents),
                $name,
            );
        }
    }

    sub _build_content_formatter {

        return sub { encode_entities "$_[0]" };
    }

    sub _build_raw_formatter { sub { map "$_", @_ } }

    sub _build_attributes_formatter {

        return sub {
            my ($name, $values) = @_;

            return sprintf('%s="%s"',
                $name,
                join(' ', @$values),
            );
        };
    }
}

1;

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Renderer::TagBased
@see_also Language::SX::Renderer::TagBased::Trait::HTMLTidy
@license  Language::SX

@class Language::SX::Renderer::Plain
Simple and plain tag based renderer

@DESCRIPTION
Implementation of a simple and plain tag style renderer based on 
L<Language::SX::Renderer::TagBased> which contains the documentation for
most parts of this implementation.

Content items will be encoded with L<HTML::Entities/encode_entities>.

=end fusion






=head1 NAME

Language::SX::Renderer::Plain - Simple and plain tag based renderer

=head1 INHERITANCE

=over 2

=item *

Language::SX::Renderer::Plain

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<Language::SX::Renderer::TagBased>

=item * L<Language::SX::Rendering>

=item * L<MooseX::Traits>

=back

=head1 DESCRIPTION

Implementation of a simple and plain tag style renderer based on 
L<Language::SX::Renderer::TagBased> which contains the documentation for
most parts of this implementation.

Content items will be encoded with L<HTML::Entities/encode_entities>.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * attributes_formatter (optional)

Initial value for the L<attributes_formatter|Language::SX::Renderer::TagBased/"attributes_formatter (optional)"> attribute
composed in by L<Language::SX::Renderer::TagBased>.

=item * content_formatter (optional)

Initial value for the L<content_formatter|Language::SX::Renderer::TagBased/"content_formatter (optional)"> attribute
composed in by L<Language::SX::Renderer::TagBased>.

=item * element_formatter (optional)

Initial value for the L<element_formatter|Language::SX::Renderer::TagBased/"element_formatter (optional)"> attribute
composed in by L<Language::SX::Renderer::TagBased>.

=item * raw_formatter (optional)

Initial value for the L<raw_formatter|Language::SX::Renderer::TagBased/"raw_formatter (optional)"> attribute
composed in by L<Language::SX::Renderer::TagBased>.

=item * valid_attribute_name (optional)

Initial value for the L<valid_attribute_name|Language::SX::Renderer::TagBased/"valid_attribute_name (required)"> attribute
composed in by L<Language::SX::Renderer::TagBased>.

=item * valid_tag_name (optional)

Initial value for the L<valid_tag_name|Language::SX::Renderer::TagBased/"valid_tag_name (required)"> attribute
composed in by L<Language::SX::Renderer::TagBased>.

=back

=head2 meta

Returns the meta object for C<Language::SX::Renderer::Plain> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Renderer::TagBased>

=item * L<Language::SX::Renderer::TagBased::Trait::HTMLTidy>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut