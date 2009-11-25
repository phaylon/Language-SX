use MooseX::Declare;

class Template::SX::Library::Inserts extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use TryCatch;
    use Template::SX::Types         qw( :all );
    use Template::SX::Constants     qw( :all );
    use Template::SX::Util          qw( :all );
    use Data::Dump                  qw( pp );
    use Scalar::Util                qw( blessed );
    use List::AllUtils              qw( uniq );
    use MooseX::Types::Structured   qw( Tuple );

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
        CodeRef                     :$file!, 
        ArrayRef[Tuple[Str,Str]]    :$args!, 
        CodeRef                     :$vars!,
        CodeRef                     :$loader!, 
        Location                    :$location!, 
        CodeRef                     :$pathfinder!
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
        CodeRef             :$file!, 
        ArrayRef[ArrayRef]  :$args, 
        CodeRef             :$vars!,
        CodeRef             :$loader!, 
        Location            :$location!, 
        CodeRef             :$pathfinder!
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

__END__

=encoding utf-8

=begin fusion

@see_also Template::SX
@see_also Template::SX/Modules
@license  Template::SX

@class Template::SX::Library::Inserts
Functionality to re-use other documents

@method make_importer
%param :$file       Callback to calculate the file to read.
%param :$args       Specification on what to import.
%param :$vars       Arguments for the document.
%param :$loader     Document loader.
%param :$location   Where the import occurred.
%param :$pathfinder Callback to locate the include path in the environment.
Builds a document import callback.

@method make_includer
%param :$file       Callback to calculate the file to include.
%param :$args       Argument stash, not currently used.
%param :$vars       Arguments for the document.
%param :$loader     Document loader.
%param :$location   Where the inclusion occurred.
%param :$pathfinder Callback to locate the include path in the environment.
Builds a document inclusion callback.

@SYNOPSIS

    ; import some values from another document
    (import "foo/bar.lib.sx" { arg: 23 } :groupname barename)

    ; include another documents return value at this point
    (include "foo/baz.inc.sx" { arg: 23 })

@DESCRIPTION
This library contains the means to include or import functionality from other documents
which allows the creation of libraries and encapsulated functionalities.

!TAG<modules>
!TAG<arguments>

=head1 PROVIDED SYNTAX ELEMENTS

=head2 import

    (import <file> { <document-arguments> } <imported> ...)

This syntax element can be used to import a set of values into the current lexical
environment. The C<file> must evaluate to a path to a file that can be found in the
L<Template::SX/include_path>.

The C<document-arguments> are passed to the document specified in C<file> as if that
document was L<run|Template::SX/run> with those arguments. The arguments are mandatory.
If you don't want to pass any arguments, specify C<{}>.

After the arguments follows the list of items to import. These can be either keywords
or barewords. A keyword will import a whole group, while a bareword will only import
that specific value.

The loaded document must be a module specifying the values you want to import as exports.
And it must accept the arguments you pass in, or an exception will be raised.

=head2 include

    (include <file> { <document-arguments> })

Syntax wise this is basically the same as L</import>, but without any arguments after 
the document arguments. This will not import anything, but instead return the document's
return value.

=end fusion






=head1 NAME

Template::SX::Library::Inserts - Functionality to re-use other documents

=head1 SYNOPSIS

    ; import some values from another document
    (import "foo/bar.lib.sx" { arg: 23 } :groupname barename)

    ; include another documents return value at this point
    (include "foo/baz.inc.sx" { arg: 23 })

=head1 INHERITANCE

=over 2

=item *

Template::SX::Library::Inserts

=over 2

=item *

L<Template::SX::Library>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 DESCRIPTION

This library contains the means to include or import functionality from other documents
which allows the creation of libraries and encapsulated functionalities.

=head1 PROVIDED SYNTAX ELEMENTS

=head2 import

    (import <file> { <document-arguments> } <imported> ...)

This syntax element can be used to import a set of values into the current lexical
environment. The C<file> must evaluate to a path to a file that can be found in the
L<Template::SX/include_path>.

The C<document-arguments> are passed to the document specified in C<file> as if that
document was L<run|Template::SX/run> with those arguments. The arguments are mandatory.
If you don't want to pass any arguments, specify C<{}>.

After the arguments follows the list of items to import. These can be either keywords
or barewords. A keyword will import a whole group, while a bareword will only import
that specific value.

The loaded document must be a module specifying the values you want to import as exports.
And it must accept the arguments you pass in, or an exception will be raised.

=head2 include

    (include <file> { <document-arguments> })

Syntax wise this is basically the same as L</import>, but without any arguments after 
the document arguments. This will not import anything, but instead return the document's
return value.

=head1 METHODS

=head2 new

Object constructor.

=over

=back

=head2 make_importer

    ->make_importer(
        CodeRef :$file!,
        ArrayRef[
            Tuple[
                Str,
                Str
            ]
        ] :$args!,
        CodeRef :$vars!,
        CodeRef :$loader!,
        Location :$location!,
        CodeRef :$pathfinder!
    )

=over

=item * Named Parameters:

=over

=item * ArrayRef[L<Tuple|MooseX::Types::Structured/Tuple>[Str,Str]] C<:$args>

Argument stash, not currently used.

=item * CodeRef C<:$file>

Callback to calculate the file to include.

=item * CodeRef C<:$loader>

Document loader.

=item * L<Location|Template::SX::Types/Location> C<:$location>

Where the inclusion occurred.

=item * CodeRef C<:$pathfinder>

Callback to locate the include path in the environment.

=item * CodeRef C<:$vars>

Arguments for the document.

=back

=back

Builds a document import callback.

=head2 make_includer

    ->make_includer(
        CodeRef :$file!,
        ArrayRef[
            ArrayRef
        ] :$args,
        CodeRef :$vars!,
        CodeRef :$loader!,
        Location :$location!,
        CodeRef :$pathfinder!
    )

=over

=item * Named Parameters:

=over

=item * ArrayRef[ArrayRef] C<:$args> (optional)

Argument stash, not currently used.

=item * CodeRef C<:$file>

Callback to calculate the file to include.

=item * CodeRef C<:$loader>

Document loader.

=item * L<Location|Template::SX::Types/Location> C<:$location>

Where the inclusion occurred.

=item * CodeRef C<:$pathfinder>

Callback to locate the include path in the environment.

=item * CodeRef C<:$vars>

Arguments for the document.

=back

=back

Builds a document inclusion callback.

=head2 meta

Returns the meta object for C<Template::SX::Library::Inserts> as an instance of L<Moose::Meta::Class>.

=head1 SEE ALSO

=over

=item * L<Template::SX>

=item * L<Template::SX/Modules>

=back

=head1 LICENSE AND COPYRIGHT

See L<Template::SX> for information about license and copyright.

=cut