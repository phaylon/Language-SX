use MooseX::Declare;

class Template::SX::Inflator::LexicalCollector {

    use MooseX::Types::Moose qw( ArrayRef Str );

    has lexicals => (
        traits      => [qw( Array )],
        is          => 'ro',
        isa         => ArrayRef[Str],
        required    => 1,
        default     => sub { [] },
        handles     => {
            add_lexical     => 'push',
            all_lexicals    => 'elements',
        },
    );

    has parent => (
        is          => 'ro',
        isa         => __PACKAGE__,
    );

    after add_lexical (@lexicals) {

        $self->parent->add_lexical(@lexicals)
            if $self->parent;
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX::Inflator
@license  Template::SX

@class Template::SX::Inflator::LexicalCollector
Collect occurances of lexical variables

@method add_lexical

    ->add_lexical(Str @lexicals)

This will add the passed lexicals to the collection and the parents collectioin
if a parent was present.

@attr lexicals
List of lexically used variables.

@attr parent
Parent collector.

=end fusion






=head1 NAME

Template::SX::Inflator::LexicalCollector - Collect occurances of lexical variables

=head1 INHERITANCE

=over 2

=item *

Template::SX::Inflator::LexicalCollector

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * lexicals (optional)

Initial value for the L<lexicals|/"lexicals (required)"> attribute.

=item * parent (optional)

Initial value for the L<parent|/"parent (optional)"> attribute.

=back

=head2 add_lexical

    ->add_lexical(Str @lexicals)

This will add the passed lexicals to the collection and the parents collectioin
if a parent was present.

=head2 all_lexicals

Delegation to a generated L<elements|Moose::Meta::Attribute::Native::MethodProvider::Array/elements> method for the L<lexicals|/lexicals (required)> attribute.

=head2 lexicals

Reader for the L<lexicals|/"lexicals (required)"> attribute.

=head2 parent

Reader for the L<parent|/"parent (optional)"> attribute.

=head2 meta

Returns the meta object for C<Template::SX::Inflator::LexicalCollector> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 lexicals (required)

=over

=item * Type Constraint

ArrayRef[Str]

=item * Default

Built during runtime.

=item * Constructor Argument

C<lexicals>

=item * Associated Methods

L<lexicals|/lexicals>, L<add_lexical|/add_lexical>, L<all_lexicals|/all_lexicals>

=back

List of lexically used variables.

=head2 parent (optional)

=over

=item * Type Constraint

L<Template::SX::Inflator::LexicalCollector>

=item * Constructor Argument

C<parent>

=item * Associated Methods

L<parent|/parent>

=back

Parent collector.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX::Inflator>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut