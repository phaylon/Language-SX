use MooseX::Declare;

class Template::SX::Library::Exceptions extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Name                       qw( subname );
    use TryCatch;
    use Data::Dump                      qw( pp );
    use Template::SX::Constants         qw( :all );
    use Template::SX::Util              qw) :all );
    use Scalar::Util                    qw( blessed );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';

    CLASS->add_functions(
        'catch' => CLASS->wrap_function('catch', { min => 2, max => 2, types => [qw( lambda lambda )] }, sub {
            my ($try, $catch) = @_;

            my $result;
            try {
                $result = $try->();
            }
            catch ($e) {
                $result = $catch->($e);
            }

            return $result;
        }),
        'error' => CLASS->wrap_function('error', { min => 1, max => 1 }, sub {
            die shift;
        }),
    );
}

__END__

=head1 NAME

Template::SX::Library::Exceptions - Handling and throwing exceptions

=head1 SYNOPSIS

    ; throw a simple error
    (error "something is wrong!")

    ; catch an error
    (catch
      (lambda () (something-that-throws-an-exception))
      (lambda (e)
        (handle-exception e)))

=head1 DESCRIPTION

This library holds the extensions for throwing and handling errors and exceptions.

=head1 PROVIDED FUNCTIONS

=head2 error

    (error <value>)

This function takes a single value of any type and will throw it with Perl's C<die> statement. If you pass it
an object, it will be thrown as an exception.

Examples:

    (error "simple text error\n")
    (error (make-some-exception-object))

=head2 catch

    (catch <try-thunk> <handle-callback>)

While L</error> allows you to throw exceptions and errors, C<catch> will allow you to handle them. The first argument
has to be a code reference that will be called without arguments. If the code reference does not throw an exception, its
return value will be returned by C<catch>. If it does raise an exception, it will be caught and the second argument will 
be invoked with the caught value as argument. It will then return the value that the handler routine returned:

    (define (safe-division . args)
      (catch
        (lambda () (apply / args))
        (lambda (e)
          (some-logger "error during division" e)
          0)))

The above will log an error and return C<0> instead of a division result if the division gave an error.

=head1 SEE ALSO

L<Template::SX>,
L<Template::SX::Library::Data::Objects>,
L<Template::SX::Library::ScopeHandling>

=cut
