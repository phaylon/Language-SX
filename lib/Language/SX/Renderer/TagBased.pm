use MooseX::Declare;

    my $RenderTree;
role Language::SX::Renderer::TagBased with Language::SX::Rendering {

    use Carp                    qw( croak );
    use Scalar::Util            qw( blessed );
    use MooseX::Types::Moose    qw( RegexpRef CodeRef );

    my @formatters = qw( raw element content attributes );

    requires map "_build_${_}_formatter", @formatters;

    has [map "${_}_formatter", @formatters]
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

    $RenderTree = sub {
        my ($item, $formatter, $regex, $path) = @_;
        
        if (ref $item eq 'ARRAY') {

            unless (@$item) {
                return ();
            }

            my ($name, @rest) = @$item;

            croak "at $path:\nfirst item in element list must be bareword"
                unless blessed $name and $name->isa('Language::SX::Runtime::Bareword');

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

    sub render_item {
        my ($self, $item) = @_;

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

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Rendering
@see_also Language::SX::Renderer::Plain
@see_also Language::SX::Runtime::Bareword
@license  Language::SX

@role Language::SX::Renderer::TagBased
Render tag-based markup out of a simple tree structure

@requires _build_attributes_formatter
Builder for the L<attributes_formatter|/"attributes_formatter (optional)">

@requires _build_element_formatter
Builder for the L<element_formatter|/"element_formatter (optional)">

@requires _build_raw_formatter
Builder for the L<raw_formatter|/"raw_formatter (optional)">

@requires _build_content_formatter
Builder for the L<content_formatter|/"content_formatter (optional)">

@attr attribute_formatter
Should return a code reference that takes a name and an array reference containing 
the values. It should return a string representing an attribute specification.

@attr content_formattter
Should return a code reference that takes a single value representing a normal,
possibly encoded, content item.

@attr element_formatter
Should return a code reference that takes a name, a list of rendered attributes as 
returned by the L<attributes_formatter|/"attributes_formatter (optional)">.

@attr raw_formatter
Should return a code reference that takes a single value representing a raw content
item.

@attr valid_attribute_name
Determines valid names for attributes.

@attr valid_tag_name
Determines valid names for element tags.

@SYNOPSIS

    `(html
      (head
        (title ,title)
        (link { rel: stylesheet type: text/css href: ,(uri-for "/static/style.css") }))
      (body
        (div { id: header }
          (h1 { id: (title page-title) } ,title))
        (div { id: content }
          (form { action: ,(uri-for "/action") method: post }
            (table { class: (dialog login) }
              (tr (td "Username")
                  (td (input { name: username })))
              (tr (td "Password")
                  (td (input { name: password type: password })))
              (tr (td { class: dialog-actions colspan: 2 }
                    (input { type: submit value: "Login" }))))))
        (div { id: footer }
          (* ,(obfuscate-email email)))))

@DESCRIPTION
Transforms a tree structure formed like the one in the L</SYNOPSIS> into tag based
markup that is specified by the consumer of this role. The format of the tree is as
follows:

=over

=item * Nodes

The root of the tree must be a single node. A node is made up of an array reference
of the following form:

    [<tagname>, <attributes>, <child> ...]

The first item is a L<bareword|Language::SX::Runtime::Bareword>. Next there can be an
optional attributes specification in form of a hash reference. If the hash reference
is not there, the element is assumed to have no attributes. Following that can be zero
to many child content items. These can be raw content, encoded content, or other nodes.

This is handled by the L<element_formatter|/"element_formatter (optional)">.

=item * Attributes

Attributes are specified as hash references. The keys are used as names of the attributes
while the value can be either a list of values in form of a hash reference, or a single
attribute value.

This is handled by the L<attributes_formatter|/"attributes_formatter (optional)">.

=item * Raw Content

A child node that starts with a C<*> bareword will have all its argument values 
stringified and interpolated as is, without further encoding or processing. This is useful
for return-values of external render functions for markdown, textile, or obfuscated
email addresses.

This is handled by the L<raw_formatter|/"raw_formatter (optional)">.

=item * Encoded Content

Every other piece of content will be stringified and handled by the
L<content_formatter|/"content_formatter (optional)">.

=back

=end fusion






=head1 NAME

Language::SX::Renderer::TagBased - Render tag-based markup out of a simple tree structure

=head1 SYNOPSIS

    `(html
      (head
        (title ,title)
        (link { rel: stylesheet type: text/css href: ,(uri-for "/static/style.css") }))
      (body
        (div { id: header }
          (h1 { id: (title page-title) } ,title))
        (div { id: content }
          (form { action: ,(uri-for "/action") method: post }
            (table { class: (dialog login) }
              (tr (td "Username")
                  (td (input { name: username })))
              (tr (td "Password")
                  (td (input { name: password type: password })))
              (tr (td { class: dialog-actions colspan: 2 }
                    (input { type: submit value: "Login" }))))))
        (div { id: footer }
          (* ,(obfuscate-email email)))))

=head1 REQUIRED METHODS

=head2 _build_attributes_formatter

Builder for the L<attributes_formatter|/"attributes_formatter (optional)">

=head2 _build_element_formatter

Builder for the L<element_formatter|/"element_formatter (optional)">

=head2 _build_raw_formatter

Builder for the L<raw_formatter|/"raw_formatter (optional)">

=head2 _build_content_formatter

Builder for the L<content_formatter|/"content_formatter (optional)">

=head1 APPLIED ROLES

=over

=item * L<Language::SX::Rendering>

=item * L<MooseX::Traits>

=back

=head1 DESCRIPTION

Transforms a tree structure formed like the one in the L</SYNOPSIS> into tag based
markup that is specified by the consumer of this role. The format of the tree is as
follows:

=over

=item * Nodes

The root of the tree must be a single node. A node is made up of an array reference
of the following form:

    [<tagname>, <attributes>, <child> ...]

The first item is a L<bareword|Language::SX::Runtime::Bareword>. Next there can be an
optional attributes specification in form of a hash reference. If the hash reference
is not there, the element is assumed to have no attributes. Following that can be zero
to many child content items. These can be raw content, encoded content, or other nodes.

This is handled by the L<element_formatter|/"element_formatter (optional)">.

=item * Attributes

Attributes are specified as hash references. The keys are used as names of the attributes
while the value can be either a list of values in form of a hash reference, or a single
attribute value.

This is handled by the L<attributes_formatter|/"attributes_formatter (optional)">.

=item * Raw Content

A child node that starts with a C<*> bareword will have all its argument values 
stringified and interpolated as is, without further encoding or processing. This is useful
for return-values of external render functions for markdown, textile, or obfuscated
email addresses.

This is handled by the L<raw_formatter|/"raw_formatter (optional)">.

=item * Encoded Content

Every other piece of content will be stringified and handled by the
L<content_formatter|/"content_formatter (optional)">.

=back

=head1 METHODS

=head2 render_item

Undocumented method.

=head2 meta

Returns the meta object for C<Language::SX::Renderer::TagBased> as an instance of L<Moose::Meta::Role>.

=head1 ATTRIBUTES

=head2 attributes_formatter (optional)

=over

=item * Type Constraint

CodeRef

=item * Default

Built lazily during runtime.

=item * Constructor Argument

C<attributes_formatter>

=back

=head2 content_formatter (optional)

=over

=item * Type Constraint

CodeRef

=item * Default

Built lazily during runtime.

=item * Constructor Argument

C<content_formatter>

=back

=head2 element_formatter (optional)

=over

=item * Type Constraint

CodeRef

=item * Default

Built lazily during runtime.

=item * Constructor Argument

C<element_formatter>

=back

Should return a code reference that takes a name, a list of rendered attributes as 
returned by the L<attributes_formatter|/"attributes_formatter (optional)">.

=head2 raw_formatter (optional)

=over

=item * Type Constraint

CodeRef

=item * Default

Built lazily during runtime.

=item * Constructor Argument

C<raw_formatter>

=back

Should return a code reference that takes a single value representing a raw content
item.

=head2 valid_attribute_name (required)

=over

=item * Type Constraint

RegexpRef

=item * Default

Built during runtime.

=item * Constructor Argument

C<valid_attribute_name>

=back

Determines valid names for attributes.

=head2 valid_tag_name (required)

=over

=item * Type Constraint

RegexpRef

=item * Default

Built during runtime.

=item * Constructor Argument

C<valid_tag_name>

=back

Determines valid names for element tags.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Rendering>

=item * L<Language::SX::Renderer::Plain>

=item * L<Language::SX::Runtime::Bareword>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut