use MooseX::Declare;

role Template::SX::Renderer::TagBased with Template::SX::Rendering {

    use Carp                    qw( croak );
    use Scalar::Util            qw( blessed );
    use MooseX::Types::Moose    qw( RegexpRef CodeRef );

    has [qw( raw_formatter element_formatter content_formatter attributes_formatter )]
        => (is => 'ro', isa => CodeRef, lazy_build => 1);

    my $IdentifierRegex = qr/\A [a-z] (?: [a-z0-9_-]* [a-z0-9] )? \Z/xi;

    has valid_tag_name => (
        is          => 'ro',
        isa         => RegexpRef,
        default     => sub { qr/ $IdentifierRegex | \* /x },
        required    => 1,
    );

    has valid_attribute_name => (
        is          => 'ro',
        isa         => RegexpRef,
        default     => sub { $IdentifierRegex },
        required    => 1,
    );

    my $RenderTree;
    $RenderTree = sub {
        my ($item, $formatter, $regex, $path) = @_;
        
        if (ref $item eq 'ARRAY') {

            unless (@$item) {
                return ();
            }

            my ($name, @rest) = @$item;

            croak "at $path:\nfirst item in element list must be bareword"
                unless blessed $name and $name->isa('Template::SX::Runtime::Bareword');

            $name = $name->value;

            croak "at $path:\ninvalid tag name '$name'"
                unless $name =~ $regex->{tag_name};

            my $path = join '/', $path, $name;

            return $formatter->{raw}->(@rest)
                if $name eq '*';

            my @attributes;
            if (scalar(@rest) and ref($rest[0]) eq 'HASH') {
                my $attrs = shift @rest;

                for my $attr_name (keys %$attrs) {
                    
                    croak "at $path:\ninvalid attribute name '$attr_name'"
                        unless $attr_name =~ $regex->{attr_name};
                    
                    push @attributes, $formatter->{attributes}->($attr_name, [

                        map { $formatter->{content}->($_) }
                            ( (ref $attrs->{ $attr_name } eq 'ARRAY') 
                              ? @{ $attrs->{ $attr_name } }
                              : $attrs->{ $attr_name }
                            )
                    ]);
                }
            }

            return $formatter->{element}->(
                $name, 
                \@attributes, 
                map { 
                    ( $RenderTree->(
                        $rest[ $_ ], 
                        $formatter, 
                        $regex, 
                        $path . "[$_]",
                    ) );
                } 0 .. $#rest
            );
        }
        else {

            return $formatter->{content}->($item);
        }
    };

    method render_item ($item) {

        return $RenderTree->(
            $item, 
            {
                raw         => $self->raw_formatter,
                element     => $self->element_formatter,
                attributes  => $self->attributes_formatter,
                content     => $self->content_formatter,
            },
            {
                tag_name    => $self->valid_tag_name,
                attr_name   => $self->valid_attribute_name,
            },
            '/',
        );
    }
}

1;
