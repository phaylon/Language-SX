use MooseX::Declare;

class Template::SX::Library::Iterators extends Template::SX::Library {
    use MooseX::ClassAttribute;
    use CLASS;

    use Sub::Name               qw( subname );
    use Template::SX::Types     qw( :all );
    use Template::SX::Constants qw( :all );
    use Template::SX::Util      qw( :all );
    use Scalar::Util            qw( blessed );

    Class::MOP::load_class($_)
        for E_PROTOTYPE;

    class_has '+syntax_map';
    class_has '+function_map';
}
