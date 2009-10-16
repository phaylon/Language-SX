package Template::SX::Constants;
use strict;
use warnings;

use constant {

    SCOPE_STRUCTURAL    => 'structural',
    SCOPE_FUNCTIONAL    => 'functional',

    CELL_NORMAL         => '(',
    CELL_SQUARE         => '[',
    CELL_CURLY          => '{',
};

use constant {

    CELL_APPLICATION    => CELL_NORMAL,
    CELL_ARRAY          => CELL_SQUARE,
    CELL_HASH           => CELL_CURLY,
    CELL_NODE           => CELL_NORMAL,
    CELL_NODE_ATTRSET   => CELL_CURLY,
};

use Sub::Exporter -setup => {
    exports => [qw(

        SCOPE_STRUCTURAL
        SCOPE_FUNCTIONAL

        CELL_NORMAL
        CELL_SQUARE
        CELL_CURLY

        CELL_APPLICATION
        CELL_ARRAY
        CELL_HASH
        CELL_NODE
        CELL_NODE_ATTRSET
    )],
};

1;
