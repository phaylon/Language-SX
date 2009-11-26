use MooseX::Declare;

class Language::SX::Library::Group {
    
    use MooseX::ClassAttribute;
    use Language::SX::Types     qw( :all );

    class_has sublibraries => (
        traits      => [qw( Array )],
        isa         => LibraryList,
        coerce      => 1,
        default     => sub { [] },
        handles     => {
            add_sublibrary      => 'push',
            all_sublibraries    => 'elements',
            find_sublibrary     => 'first',
            map_sublibraries    => 'map',
        },
    );

    method function_names { map { ($_->function_names) } $self->all_sublibraries }
    method syntax_names   { map { ($_->syntax_names) }   $self->all_sublibraries }

    method additional_inflator_traits {
        return $self->map_sublibraries(sub { ($_->additional_inflator_traits) });
    }

    method has_setter (Str $name) {

        for my $lib ($self->all_sublibraries) {
            return $lib if $lib->has_setter($name);
        }

        return undef;
    }

    method has_syntax (Str $name) {

        for my $lib ($self->all_sublibraries) {
            return $lib if $lib->has_syntax($name);
        }

        return undef;
    }

    method has_function (Str $name) {

        my $lib = $self->find_sublibrary(sub { $_->has_function($name) })
            or return undef;

        return $lib;
    }

    method get_functions (Str @names) {
        
        my @functions = map {

            my $name = $_;
            my $lib  = $self->find_sublibrary(sub { $_->has_function($name) });

            $lib ? $lib->get_functions($name) : undef;

        } @names;

        return wantarray ? @functions : $functions[-1];
    }

    method get_setter (Str @names) {
        
        my @setter = map {

            my $name = $_;
            my $lib  = $self->find_sublibrary(sub { $_->has_setter($name) });

            $lib ? $lib->get_setter($name) : undef;

        } @names;

        return wantarray ? @setter : $setter[-1];
    }

    method get_syntax (Str @names) {
        
        my @syntax = map {

            my $name = $_;
            my $lib  = $self->find_sublibrary(sub { $_->has_syntax($name) });

            $lib ? $lib->get_syntax($name) : undef;

        } @names;

        return wantarray ? @syntax : $syntax[-1];
    }
}

__END__

=encoding utf-8

=begin fusion

@see_also Language::SX
@see_also Language::SX::Library::Core
@see_also Language::SX::Library::Data
@license  Language::SX

@class Language::SX::Library::Group
Library group base functionality

@method additional_inflator_traits
Will return all inflator traits required by one of the group's libraries.

@method function_names
Will return the names of all functions in this group as list.

@method get_functions
Will fetch the specified functions from the libraries.

@method get_setter
Will fetch the specified setters from the libraries.

@method get_syntax
Will fetch the specified syntax elements from the libraries.

@method has_function
Will return the library that was first found containing a function with
this name.

@method has_setter
Will return the library that was first found containing a setter with
this name.

@method has_syntax
Will return the library that was first found containing a syntax element
with this name.

@method syntax_names
Will return a list of all known syntax element names from this group.

@synopsis

    use MooseX::Declare;

    class MyLibrary extends Language::SX::Library::Group {
        use MooseX::ClassAttribute;

        class_has '+sublibraries';
        __PACKAGE__->add_sublibraries(@library_objects);
    }

@description
This package contains the main group functionality. Library groups are objects
dispatching to the libraries contained within the group.

=end fusion






=head1 NAME

Language::SX::Library::Group - Library group base functionality

=head1 SYNOPSIS

    use MooseX::Declare;

    class MyLibrary extends Language::SX::Library::Group {
        use MooseX::ClassAttribute;

        class_has '+sublibraries';
        __PACKAGE__->add_sublibraries(@library_objects);
    }

=head1 INHERITANCE

=over 2

=item *

Language::SX::Library::Group

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 DESCRIPTION

This package contains the main group functionality. Library groups are objects
dispatching to the libraries contained within the group.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 additional_inflator_traits

    ->additional_inflator_traits(@)

=over

=back

Will return all inflator traits required by one of the group's libraries.

=head2 function_names

    ->function_names(@)

=over

=back

Will return the names of all functions in this group as list.

=head2 get_functions

    ->get_functions(Str @names)

=over

=item * Positional Parameters:

=over

=item * Str C<@names>

=back

=back

Will fetch the specified functions from the libraries.

=head2 get_setter

    ->get_setter(Str @names)

=over

=item * Positional Parameters:

=over

=item * Str C<@names>

=back

=back

Will fetch the specified setters from the libraries.

=head2 get_syntax

    ->get_syntax(Str @names)

=over

=item * Positional Parameters:

=over

=item * Str C<@names>

=back

=back

Will fetch the specified syntax elements from the libraries.

=head2 has_function

    ->has_function(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Will return the library that was first found containing a function with
this name.

=head2 has_setter

    ->has_setter(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Will return the library that was first found containing a setter with
this name.

=head2 has_syntax

    ->has_syntax(Str $name)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

=back

=back

Will return the library that was first found containing a syntax element
with this name.

=head2 syntax_names

    ->syntax_names(@)

=over

=back

Will return a list of all known syntax element names from this group.

=head2 meta

Returns the meta object for C<Language::SX::Library::Group> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Language::SX>

=item * L<Language::SX::Library::Core>

=item * L<Language::SX::Library::Data>

=back

=head1 LICENSE AND COPYRIGHT

See L<Language::SX> for information about license and copyright.

=cut