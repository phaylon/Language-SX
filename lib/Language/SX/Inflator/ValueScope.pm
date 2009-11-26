use MooseX::Declare;

class Language::SX::Inflator::ValueScope {

    class ::Variable with Language::SX::Document::Locatable {

        use Data::Dump              qw( pp );
        use MooseX::Types::Moose    qw( Int Str );
        use Language::SX::Types;

        my $LastID = 0;

        has id => (
            is          => 'ro',
            isa         => Int,
            init_arg    => undef,
            required    => 1,
            default     => sub { $LastID++ },
        );

        has prefix => (
            is          => 'ro',
            isa         => Str,
            required    => 1,
        );

        has scopename => (
            is          => 'ro',
            isa         => Str,
            required    => 1,
        );

        method name { join '_' => $self->prefix, $self->id }

        method compile { sprintf '%s->(getter_for => %s)', $self->scopename, pp($self->name) }
    }

    use MooseX::Types::Moose    qw( Object HashRef Int ArrayRef );
    use Language::SX::Constants qw( :all );
    use Data::Dump              qw( pp );

    has variables => (
        traits      => [qw( Hash )],
        isa         => HashRef[Object],
        required    => 1,
        default     => sub { {} },
        handles     => {
            _var_count  => 'count',
            _var_set    => 'set',
            _var_source => 'get',
            _var_names  => 'keys',
        },
    );

    my $LastScopeID = 0;

    has id => (
        is          => 'ro',
        isa         => Int,
        init_arg    => undef,
        required    => 1,
        init_arg    => undef,
        default     => sub { $LastScopeID++ },
    );

    method varname { join '_', '$SCOPE', $self->id }
    
    method add_variable (Object $source, Str $name = "anon") {
        
        my $var = Language::SX::Inflator::ValueScope::Variable->new(
            prefix      => $name,
            location    => $source->location,
            scopename   => $self->varname,
        );

        $self->_var_set($var->name, $source);

        return $var;
    }

    method wrap (Str $body, Language::SX::Inflator $inf) {

        return $body unless $self->_var_count;

        return sprintf(
            '(do { my %s = %s; %s->(enclose => %s) })',
            $self->varname,
            $inf->render_call(
                library => 'Language::SX::Library::ScopeHandling',
                method  => 'make_value_scope',
                args    => {
                    variables => sprintf(
                        '(+{ %s })',
                        join(', ',
                            map {
                                (pp($_), $self->_var_source($_)->compile($inf, SCOPE_FUNCTIONAL))
                            } $self->_var_names,
                        ),
                    ),
                },
            ),
            $self->varname,
            $body,
        );
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Inflator
@license  Language::SX

@class Language::SX::Inflator::ValueScope
Internal usage of a lexically runtime scoped value

@method add_variable
Adds a new value to the scope and returns the variable object that can be used to
access the value.

@method varname
Returns the variable name for the scope.

@method wrap
Wraps a precompiled body with a scope that makes the created variables accessible.
If no variables were created, the C<$body> will be returned as is.

@attr id
Identifies the scope.

@attr variables
A hash keyed by variable name with the value source objects as values.

@description
This is an internally used class that provides ways to precalculate one or more
values during runtime and use them without re-evaluating an expression repeatedly.

=end fusion






=head1 NAME

Language::SX::Inflator::ValueScope - Internal usage of a lexically runtime scoped value

=head1 INHERITANCE

=over 2

=item *

Language::SX::Inflator::ValueScope

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This is an internally used class that provides ways to precalculate one or more
values during runtime and use them without re-evaluating an expression repeatedly.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * variables (optional)

Initial value for the L<variables|/"variables (required)"> attribute.

=back

=head2 add_variable

    ->add_variable(Object $source, Str $name = "anon")

=over

=item * Positional Parameters:

=over

=item * Object C<$source>

=item * Str C<$name>

=back

=back

Adds a new value to the scope and returns the variable object that can be used to
access the value.

=head2 id

Reader for the L<id|/"id (required)"> attribute.

=head2 varname

    ->varname(@)

=over

=back

Returns the variable name for the scope.

=head2 wrap

    ->wrap(Str $body, Language::SX::Inflator $inf)

=over

=item * Positional Parameters:

=over

=item * Str C<$body>

=item * L<Language::SX::Inflator> C<$inf>

=back

=back

Wraps a precompiled body with a scope that makes the created variables accessible.
If no variables were created, the C<$body> will be returned as is.

=head2 meta

Returns the meta object for C<Language::SX::Inflator::ValueScope> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>.

=head1 ATTRIBUTES

=head2 id (required)

=over

=item * Type Constraint

Int

=item * Default

Built during runtime.

=item * Constructor Argument

This attribute can not be directly set at object construction.

=item * Associated Methods

L<id|/id>

=back

Identifies the scope.

=head2 variables (required)

=over

=item * Type Constraint

HashRef[Object]

=item * Default

Built during runtime.

=item * Constructor Argument

C<variables>

=item * Associated Methods

=back

A hash keyed by variable name with the value source objects as values.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Inflator>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut