use MooseX::Declare;

class Template::SX::Renderer::Plain with Template::SX::Renderer::TagBased {

    use HTML::Entities qw( encode_entities );

    method _build_element_formatter {

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

    method _build_content_formatter {

        return sub { encode_entities "$_[0]" };
    }

    method _build_raw_formatter { sub { map "$_", @_ } }

    method _build_attributes_formatter {

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

@see_also Template::SX
@see_also Template::SX::Renderer::TagBased
@see_also Template::SX::Renderer::TagBased::Trait::HTMLTidy
@license  Template::SX

@class Template::SX::Renderer::Plain
Simple and plain tag based renderer

@DESCRIPTION
Implementation of a simple and plain tag style renderer based on 
L<Template::SX::Renderer::TagBased> which contains the documentation for
most parts of this implementation.

Content items will be encoded with L<HTML::Entities/encode_entities>.

=end fusion






=head1 NAME

Template::SX::Renderer::Plain - Simple and plain tag based renderer

=head1 INHERITANCE

=over 2

=item *

Template::SX::Renderer::Plain

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<MooseX::Traits>

=item * L<Template::SX::Renderer::TagBased>

=item * L<Template::SX::Rendering>

=back

=head1 DESCRIPTION

Implementation of a simple and plain tag style renderer based on 
L<Template::SX::Renderer::TagBased> which contains the documentation for
most parts of this implementation.

Content items will be encoded with L<HTML::Entities/encode_entities>.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * attributes_formatter (optional)

Initial value for the L<attributes_formatter|Template::SX::Renderer::TagBased/"attributes_formatter (optional)"> attribute
composed in by L<Template::SX::Renderer::TagBased>.

=item * content_formatter (optional)

Initial value for the L<content_formatter|Template::SX::Renderer::TagBased/"content_formatter (optional)"> attribute
composed in by L<Template::SX::Renderer::TagBased>.

=item * element_formatter (optional)

Initial value for the L<element_formatter|Template::SX::Renderer::TagBased/"element_formatter (optional)"> attribute
composed in by L<Template::SX::Renderer::TagBased>.

=item * raw_formatter (optional)

Initial value for the L<raw_formatter|Template::SX::Renderer::TagBased/"raw_formatter (optional)"> attribute
composed in by L<Template::SX::Renderer::TagBased>.

=item * valid_attribute_name (optional)

Initial value for the L<valid_attribute_name|Template::SX::Renderer::TagBased/"valid_attribute_name (required)"> attribute
composed in by L<Template::SX::Renderer::TagBased>.

=item * valid_tag_name (optional)

Initial value for the L<valid_tag_name|Template::SX::Renderer::TagBased/"valid_tag_name (required)"> attribute
composed in by L<Template::SX::Renderer::TagBased>.

=back

=head2 meta

Returns the meta object for C<Template::SX::Renderer::Plain> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Renderer::TagBased>

=item * L<Template::SX::Renderer::TagBased::Trait::HTMLTidy>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut