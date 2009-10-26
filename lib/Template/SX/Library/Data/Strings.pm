use MooseX::Declare;

class Template::SX::Library::Data::Strings extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
    class_has '+setter_map';

    CLASS->add_functions(
        'string'  => sub { join '', @_ },
        'string?' => CLASS->wrap_function('string?', { min => 1 }, sub {
            return scalar( grep { ref or not defined } @_ ) ? undef : 1;
        }),
    );

    CLASS->add_functions(
        'eq?' => CLASS->_build_equality_operator(   eq => 'eq?'),
        'ne?' => CLASS->_build_nonequality_operator(ne => 'ne?'),
        'lt?' => CLASS->_build_sequence_operator(   lt => 'lt?'),
        'le?' => CLASS->_build_sequence_operator(   le => 'le?'),
        'gt?' => CLASS->_build_sequence_operator(   gt => 'gt?'),
        'ge?' => CLASS->_build_sequence_operator(   ge => 'ge?'),
    );

    CLASS->add_functions(
        'upper'         => CLASS->_build_unary_builtin_function('uc', 'upper'),
        'lower'         => CLASS->_build_unary_builtin_function('lc', 'lower'),
        'upper-first'   => CLASS->_build_unary_builtin_function('ucfirst', 'upper-first'),
        'lower-first'   => CLASS->_build_unary_builtin_function('lcfirst', 'lower-first'),
    );
}
