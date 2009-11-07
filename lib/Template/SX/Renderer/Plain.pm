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

    method _build_raw_formatter { sub { "$_[0]" } }

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
