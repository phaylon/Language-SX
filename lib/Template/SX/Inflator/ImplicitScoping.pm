use MooseX::Declare;

role Template::SX::Inflator::ImplicitScoping {

    requires qw( compile_scoped );
}
