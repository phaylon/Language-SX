use MooseX::Declare;

class Template::SX::Inflator::ModuleMeta {

    use TryCatch;
    use Data::Dump                  qw( pp );
    use Template::SX::Constants     qw( :all );
    use List::AllUtils              qw( uniq );
    use MooseX::Types::Structured   qw( Dict );
    use MooseX::Types::Moose        qw( ArrayRef HashRef Str );
    use Template::SX::Types         qw( :all );

    Class::MOP::load_class($_)
        for E_SYNTAX;

    has arguments => (
        is          => 'ro',
        isa         => Dict[ optional => HashRef, required => HashRef ],
    );

    has requires => (
        is          => 'ro',
        isa         => LibraryList,
        coerce      => 1,
    );

    has exports => (
        is          => 'ro',
        isa         => HashRef[ArrayRef[Str]],
    );

    method lexicals () {

        return () unless $self->arguments;
        return( map { (keys %$_) } grep defined, values %{ $self->arguments } );
    }

    method new_from_tree (ClassName $class: ArrayRef[Object] :$arguments!) {

        my %attrs;

        for my $node (@$arguments) {
            
            E_SYNTAX->throw(
                message     => 'module declaration expects (option value1 value2 ...) list arguments',
                location    => $node->location,
            ) unless $node->isa('Template::SX::Document::Cell::Application') and $node->node_count;

            my ($option, @elements) = $node->all_nodes;

            E_SYNTAX->throw(
                message     => 'module declaration option needs name as first item',
                location    => $option->location,
            ) unless $option->isa('Template::SX::Document::Bareword');

            my $method = $class->can('_parse_' . $option->value)
                or E_SYNTAX->throw(
                    message     => sprintf(q(unknown module declaration option '%s'), $option->value),
                    location    => $option->location,
                );

            E_SYNTAX->throw(
                message     => sprintf(q(double declaration of '%s' option is illegal), $option->value),
                location    => $node->location,
            ) if $attrs{ $option->value };

            $attrs{ $option->value } = $class->$method(elements => \@elements);
        }

        return $class->new(%attrs);
    }

    method _parse_arguments (ClassName $class: ArrayRef[Object] :$elements) {

        my %required;
        my %optional;
        my $target = \%required;

        for my $node (@$elements) {

            E_SYNTAX->throw(
                message     => 'list of arguments must be barewords',
                location    => $node->location,
            ) unless $node->isa('Template::SX::Document::Bareword');

            if ($node->is_dot) {
                $target = \%optional;
                next;
            }

            $target->{ $node->value } = 1;
        }

        return +{
            required => \%required,
            optional => \%optional,
        };
    }

    method _parse_exports (ClassName $class: ArrayRef[Object] :$elements) {

        my %export_groups;
        my @exports;

        for my $node (@$elements) {

            if ($node->isa('Template::SX::Document::Bareword')) {

                push @exports, $node->value;
            }
            elsif ($node->isa('Template::SX::Document::Cell::Application')) {

                E_SYNTAX->throw(
                    message     => 'export group declaration cannot be empty',
                    location    => $node->location,
                ) unless $node->node_count;

                my ($name, @words) = $node->all_nodes;

                E_SYNTAX->throw(
                    message     => 'first item in export group declaration must be group name as keyword',
                    location    => $name->location,
                ) unless $name->isa('Template::SX::Document::Keyword');

                $_->isa('Template::SX::Document::Bareword')
                    or E_SYNTAX->throw(
                        message     => 'export group declaration arguments must be barewords',
                        location    => $_->location,
                    )
                  for @words;

                $export_groups{ $name->value } = [map { $_->value } @words];
            }
            else {

                E_SYNTAX->throw(
                    message     => 'export declaration argument must be bareword or list',
                    location    => $node->location,
                );
            }
        }

        my @all = uniq
            @exports,
            map  { (@{ $export_groups{ $_ } }) } 
            keys %export_groups;

        return +{
            %export_groups,
            all => \@all,
        };
    }

    method _parse_requires (ClassName $class: ArrayRef[Object] :$elements) {

        my @libraries;

        for my $library (@$elements) {

            E_SYNTAX->throw(
                message     => 'required library declaration argument must be bareword or string constant',
                location    => $library->location,
            ) unless $library->isa('Template::SX::Document::Bareword')
                  or $library->isa('Template::SX::Document::String::Constant');

            push @libraries, $library->value;
        }

        return \@libraries;
    }

    method compile (Template::SX::Inflator $inf) {

        return join(';',
            $self->_compile_safety($inf),
            $self->_compile_libraries($inf),
            $self->_compile_arguments($inf),
            $self->_compile_exports($inf),
        );
    }

    method _compile_arguments (Object $inf) {

        return () unless $self->arguments;

        return '$Template::SX::MODULE_META->{arguments} = ' . pp($self->arguments);
    }

    method _compile_exports (Object $inf) {

        return () unless $self->exports;

        return '$Template::SX::MODULE_META->{exports} = ' . pp($self->exports);
    }

    method _compile_safety (Object $inf) {

        return sprintf(
            'unless (%s) { require %s, %s->throw(class => %s, attributes => %s) }',
            '$Template::SX::MODULE_META',
            ( E_PROTOTYPE ) x 2,
            pp( E_INTERNAL ),
            pp({ message => 'unable to store meta information, document environment seems to be missing' }),
        );
    }

    method _compile_libraries (Object $inf) {

        return () unless $self->requires;

        for my $library (@{ $self->requires }) {

            $inf->add_library($library);
        }
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Inflator
@license  Template::SX

@class Template::SX::Inflator::ModuleMeta
Contain and render module meta information.

@method compile
Compiles the meta information into inflator code.

@method lexicals
Returns a list of new lexicals introduced by this module's arguments.

@method new_from_tree
%param :$arguments Syntax arguments.
Create a new C<ModuleMeta> out of a document tree.

@attr arguments
Map of required and optional arguments.

@attr exports
List of type export groups.

@attr requires
Required libraries.

@DESCRIPTION
This module contains and renders the module meta information required for argument
validation, per-document library loading, and export declarations.

=end fusion






=head1 NAME

Template::SX::Inflator::ModuleMeta - Contain and render module meta information.

=head1 INHERITANCE

=over 2

=item *

Template::SX::Inflator::ModuleMeta

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This module contains and renders the module meta information required for argument
validation, per-document library loading, and export declarations.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * arguments (optional)

Initial value for the L<arguments|/"arguments (optional)"> attribute.

=item * exports (optional)

Initial value for the L<exports|/"exports (optional)"> attribute.

=item * requires (optional)

Initial value for the L<requires|/"requires (optional)"> attribute.

=back

=head2 arguments

Reader for the L<arguments|/"arguments (optional)"> attribute.

=head2 compile

    ->compile(Template::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * L<Template::SX::Inflator> C<$inf>

=back

=back

Compiles the meta information into inflator code.

=head2 exports

Reader for the L<exports|/"exports (optional)"> attribute.

=head2 lexicals

    ->lexicals()

=over

=back

Returns a list of new lexicals introduced by this module's arguments.

=head2 new_from_tree

    ->new_from_tree(ClassName $class: ArrayRef[Object] :$arguments!)

=over

=item * Named Parameters:

=over

=item * ArrayRef[Object] C<:$arguments>

Syntax arguments.

=back

=back

Create a new C<ModuleMeta> out of a document tree.

=head2 requires

Reader for the L<requires|/"requires (optional)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Inflator::ModuleMeta> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 arguments (optional)

=over

=item * Type Constraint

L<Dict|MooseX::Types::Structured/Dict>[optional,HashRef,required,HashRef]

=item * Constructor Argument

C<arguments>

=item * Associated Methods

L<arguments|/arguments>

=back

Map of required and optional arguments.

=head2 exports (optional)

=over

=item * Type Constraint

HashRef[ArrayRef[Str]]

=item * Constructor Argument

C<exports>

=item * Associated Methods

L<exports|/exports>

=back

List of type export groups.

=head2 requires (optional)

=over

=item * Type Constraint

L<LibraryList|Template::SX::Types/LibraryList>

=item * Constructor Argument

C<requires>

=item * Associated Methods

L<requires|/requires>

=back

Required libraries.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Inflator>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut