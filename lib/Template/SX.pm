use MooseX::Declare;

class Template::SX {

    with 'MooseX::Traits';

    use Template::SX::Types;
    use MooseX::Types::Moose qw( CodeRef );
    use MooseX::MultiMethods;

    has reader => (
        is          => 'ro', 
        isa         => 'Template::SX::Reader', 
        required    => 1, 
        lazy_build  => 1,
        handles     => {
            read_string => 'read',
        },
    );

    has '+_trait_namespace' => (
        default     => 'Template::SX::Trait',
    );

    method _build_reader {

        require Template::SX::Reader;
        return Template::SX::Reader->new;
    }

    method compile_document (Template::SX::Document $doc) {
        return $doc->compile;
    }

    method load_compiled (Str $body) {

        local $@;
        my $code = eval sprintf 'package Template::SX::VOID; %s', $body;

        if ($@) {

            # FIXME throw exception
            die "Unable to load compiled code: $@\n";
        }
        elsif (not is_CodeRef $code) {

            # FIXME throw exception
            die "Invalid compilation result, not a code reference\n";
        }

        return $code;
    }

    multi method compile (Str :$string) {

        my $doc  = $self->read_string($string);
        my $body = $self->compile_document($doc);
        print "COMPILED:\n$body\n";

        return $body;
    }

    multi method load (Str :$string) {

        return $self->load_compiled(
            $self->compile(string => $string),
        );
    }

    multi method run (Str :$string, HashRef :$vars = {}) {
        
        my $code = $self->load(string => $string);
        return scalar $code->(%$vars);
    }
}
