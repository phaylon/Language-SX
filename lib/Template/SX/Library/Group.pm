use MooseX::Declare;

class Template::SX::Library::Group {
    
    use MooseX::ClassAttribute;
    use Template::SX::Types     qw( :all );

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
        
        my @etter = map {

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
