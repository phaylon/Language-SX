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
        },
    );

    method has_function (Str $name) {

        my $lib = $self->find_sublibrary(sub { $_->has_function($name) })
            or return undef;

        return 1;
    }

    method get_functions (Str @names) {
        
        my @functions = map {

            my $name = $_;
            my $lib  = $self->find_sublibrary(sub { $_->has_function($name) });

            $lib ? $lib->get_functions($name) : undef;

        } @names;

        return wantarray ? @functions : $functions[-1];
    }
}
