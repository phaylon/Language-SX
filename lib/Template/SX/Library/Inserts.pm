use MooseX::Declare;

class Template::SX::Library::Inserts extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use TryCatch;
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );
    use Data::Dump              qw( pp );
    use Scalar::Util            qw( blessed );
    use List::AllUtils          qw( uniq );

    Class::MOP::load_class($_)
        for E_PROTOTYPE, E_SYNTAX, E_TYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    method _build_inserter (ClassName $class: Str $name, Str $maker, Int $max_args?) {

        return sub {
            my $self = shift;
            my $inf  = shift;
            my $cell = shift;

            E_SYNTAX->throw(
                message     => "$name expects file path and optional argument hash",
                location    => $cell->location,
            ) if (defined($max_args) and @_ > $max_args) or @_ < 1;

            my ($file, $vars, @args) = @_;

            @args = map {

                $_->isa('Template::SX::Document::Bareword')     ? pp([bare  => $_->value])
              : $_->isa('Template::SX::Document::Keyword')      ? pp([group => $_->value])
              : E_SYNTAX->throw(
                    message     => 'import list is expected to contain keywords and barewords only',
                    location    => $_->location,
                )

            } @args;

            return $inf->render_call(
                library => $CLASS,
                method  => $maker,
                args    => {
                    file            => $file->compile($inf, SCOPE_FUNCTIONAL),
                    loader          => '$inf->build_document_loader',
                    pathfinder      => '$inf->build_path_finder',
                    vars            => ( $vars ? $vars->compile($inf, SCOPE_FUNCTIONAL) : 'sub { {} }' ),
                    args            => sprintf('[%s]', join ', ', @args),
                    location        => pp($cell->location),
                },
            );
        };
    }

    CLASS->add_syntax(
        include => CLASS->_build_inserter(qw( include make_includer 2 )),
        import  => CLASS->_build_inserter(qw( import  make_importer )),
    );

    method make_importer (
        CodeRef             :$file, 
        ArrayRef[ArrayRef]  :$args, 
        CodeRef             :$vars,
        CodeRef             :$loader, 
        Location            :$location, 
        CodeRef             :$pathfinder
    ) {
        my @groups = map { $_->[1] } grep { $_->[0] eq 'group' } @$args;
        my @bare   = map { $_->[1] } grep { $_->[0] eq 'bare'  } @$args;

        return sub {
            my $env    = shift;
            my $path   = $pathfinder->($env);
            my $values = $vars->($env);

            try {
                my $doc = $loader->( $path->file( $file->($env) ) );

                E_TYPE->throw(message => 'import arguments must be passed as a hash', location => $location)
                    unless ref $values eq 'HASH';

                $doc->run(vars => $values, include_path => $path);

                my @import = (
                    ( map { ($doc->exports_in_group($_)) } @groups ),
                    @bare,
                );

                $env->{vars}{ $_ } = $doc->last_exported($_)
                    for @import;
            }
            catch (Template::SX::Exception::Prototype $e) {
                $e->throw_at($location);
            }
            catch (Any $e) {
                die $e;
            }

            return undef;
        };
    }

    method make_includer (
        CodeRef             :$file, 
        ArrayRef[ArrayRef]  :$args, 
        CodeRef             :$vars,
        CodeRef             :$loader, 
        Location            :$location, 
        CodeRef             :$pathfinder
    ) {

        return sub {
            my $env    = shift;
            my $path   = $pathfinder->($env);
            my $values = $vars->($env);

            my $result;

            try {
                my $doc = $loader->( $path->file( $file->($env) ) );

                E_TYPE->throw(message => 'include arguments must be passed as a hash', location => $location)
                    unless ref $values eq 'HASH';

                $result = $doc->run(vars => $values, include_path => $path);
            }
            catch (Template::SX::Exception::Prototype $e) {
                $e->throw_at($location);
            }
            catch (Any $e) {
                die $e;
            }

            return $result;
        };
    }
}
