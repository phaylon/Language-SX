#!/usr/bin/env perl
use strict;
use warnings;
use Language::SX::Constants qw( :all );
use Language::SX::Test      qw( :all );
use Test::Most;
use utf8;

my @try = (
    ['(define foo 23) (define bar 42) (+ foo bar)',     65,         'succeeding definitions'],
    ['(define foo) foo',                                undef,      'definition without value'],

    ['((lambda (x y) (+ x y)) 3 4)',                    7,          'lambda generation and application'],
    ['((lambda args args) 1 2)',                        [1, 2],     'lambda generation with all argument capture'],
    ['((lambda (x . ls) ls) 1 2 3)',                    [2, 3],     'lambda generation with rest capture'],
    ['((lambda (. ls) ls) 1 2 3)',                      [1, 2, 3],  'lambda generation with dot at signature start'],
);

push @try, [q{

    (define kons (lambda (n m) (lambda (a) (a n m))))
    (define kar  (lambda (k) (k (lambda (n m) n))))
    (kar (kons 5 6))

}, 5, 'kar/kdr example'];

push @try, [q{

    (define (((add x) y) z) (+ x y z))
    (((add 3) 4) 5)

}, 12, 'definition shortcut with generator'];

push @try, [q{

    (define (my+ x y) (+ x y))
    (my+ 2 3)

}, 5, 'simple shortcut lambda definition'];

push @try, [q{

    (let [(x 3) (y 4)]
      (+ x y))

}, 7, 'simple let'];

push @try, [q{

    (let ((x 3) 
          (y 4))
      (let ((x (* x 2))
            (y (+ y 1)))
        `(,x ,y)))

}, [6, 5], 'shadowing of simple let'];

push @try, [q{

    (let* ((x 3)
           (y (+ x 1)))
      y)

}, 4, 'simple let*'];

push @try, [q{

    (define x 3)
    (let* ((x (+ x 1)) (x (+ x 1))) x)

}, 5, 'shadowing of let*'];

push @try, [q{

    (let-rec ((foo (lambda (n) (+ n 1)))
              (bar (lambda (n) `(,(foo n) ,(baz n))))
              (baz (lambda (n) (- n 1))))
      (bar 23))

}, [24, 22], 'simple let-rec'];

push @try, [q{

    (let ((kons (λ (n m) (λ (p) (p n m))))
          (kar  (λ (k) (k (λ (n m) n))))
          (kdr  (λ (k) (k (λ (n m) m)))))
      (let ((foo (kons (kons 1 2)
                       (kons 3 4))))
        `(,(kar (kar foo))
          ,(kar (kdr foo))
          ,(kdr (kar foo))
          ,(kdr (kdr foo)))))


}, [1, 3, 2, 4], 'lambda unicode shortcut'];

push @try, [q{

    ((-> (+ (* _ 2) (* _ 3))) 3)

}, 15, 'single argument lambda shortcut'];

push @try, [q{

    (define x)
    (list
      (set! x 23)
      x)

}, [23, 23], 'setting a variable'];

push @try, [
    q{
        (define count-up
          (let ((n -1))
            (<- (set! n (++ n)))))
        (map `(a: b: c: d:)
             (-> { _ (count-up) }))
    },
    [{ a => 0 }, { b => 1 }, { c => 2 }, { d => 3 }],
    'thunk iteration',
];

push @try, [
    q{
        (list
          (let ((let (<- 23)) (let* 42))
            (+ (let) let*))
          (let* ((let 23) (let* (<- (+ let 42))))
            (list let (let*)))
          (let-rec ((let (<- let*)) (let* 23))
            (let)))
    },
    [65, [23, 65], 23],
    'shadowing syntax with let variants',
];

push @try, [
    q{
        (define foo (lambda (lambda . define) (list (lambda) define)))
        (define (bar lambda . define) (list (lambda) define))

        (list (foo (<- 23) 42)
              (bar (<- 17) 13))
    },
    [ [23, [42]], [17, [13]] ],
    'shadowing syntax with lambda and lambda definition shortcut',
];

push @try, [
    q{
        (define foo 23)
        (list
          (apply! foo ++)
          foo)
    },
    [24, 24],
    'simple variable apply!',
];

push @try, [
    q{
        (define (sum-1 n) (if (> 0 n) 0 (+ (sum-1 (-- n)) n)))
        (define sum-2 (-> (if (> 0 _) 0 (+ (sum-2 (-- _)) _))))

        (list (sum-1 3) (sum-2 4))
    },
    [6, 10],
    'self-calling function definition',
];

with_libs(sub {
    die_on_fail;

    is_result @$_ for @try;

    do {
        my $l = sx_run '(import/types Moose) (lambda ((Int x where even?)) x)';
        is $l->(6), 6, 'lambda with typed parameter';

        throws_ok { $l->("foo") } E_PROTOTYPE, 'wrong type for value throws exception';
        is $@->class, E_PARAMETER, 'thrown exception would be parameter';
        like $@, qr/Int/, 'type constraint in error message';

        throws_ok { $l->(3) } E_PROTOTYPE, 'wrong value but correct type throws exception';
        is $@->class, E_PARAMETER, 'thrown exception would be parameter';
        like $@, qr/custom/, 'correct error message';


        my $d = sx_run '(import/types Moose) (define (foo (Int x where even?)) x) foo';
        is $d->(6), 6, 'define with typed parameter';

        throws_ok { $d->("foo") } E_PROTOTYPE, 'wrong type for value throws exception';
        is $@->class, E_PARAMETER, 'thrown exception would be parameter';
        like $@, qr/Int/, 'type constraint in error message';

        throws_ok { $d->(3) } E_PROTOTYPE, 'wrong value but correct type throws exception';
        is $@->class, E_PARAMETER, 'thrown exception would be parameter';
        like $@, qr/custom/, 'correct error message';


        throws_ok { sx_run '(lambda ((Int)) 23)' } E_SYNTAX, 'single item in parameter specification raises exception';
        like $@, qr/type and a name/, 'correct error message';

        throws_ok { sx_run '((lambda ((3 foo)) foo) 3)' } E_TYPE, 'numeric type in parameter specification raises exception';
        like $@, qr/type constraint/, 'correct error message';

        throws_ok { sx_run '((lambda ((foo 3)) foo) 3)' } E_SYNTAX, 'numeric variable name in parameter specification raises exception';
        like $@, qr/bareword/, 'correct error message';

        throws_ok { sx_run '((lambda ((Int foo 3)) foo) 3)' } E_SYNTAX, 'numeric option name in parameter specification raises exception';
        like $@, qr/bareword/, 'correct error message';

        throws_ok { sx_run '((lambda ((Int foo is 3)) foo) 3)' } E_SYNTAX, 'numeric trait name in parameter specification raises exception';
        like $@, qr/bareword/, 'correct error message';


        throws_ok { sx_run '(import/types Moose) ((lambda ((Int foo where 3)) foo) 3)' } E_TYPE, 
            'numeric where condition in parameter specification raises exception';
        like $@, qr/code reference/, 'correct error message';

        throws_ok { sx_run '(import/types Moose) ((lambda ((Int foo gnargh 3)) foo) 3)' } E_SYNTAX, 
            'unknown option name in parameter specification raises exception';
        like $@->message, qr/option.*gnargh/, 'correct error message';

        throws_ok { sx_run '(import/types Moose) ((lambda ((Int foo is gnargh)) foo) 3)' } E_SYNTAX, 
            'unknown trait name in parameter specification raises exception';
        like $@->message, qr/trait.*gnargh/, 'correct error message';
    };

    for my $wrong_arg_count ('(lambda)', '(lambda (x))') {

        throws_ok { sx_load $wrong_arg_count } E_SYNTAX, 'lambda with missing arguments raises syntax exception';
        like $@, qr/lambda.*arguments/, 'correct error message';
        is $@->location->{line}, 1, 'correct line number';
        is $@->location->{char}, 1, 'correct char number';
    }

    throws_ok { sx_load '(lambda 23 7)' } E_SYNTAX, 'invalid lambda parameter specification';
    like $@, qr/lambda.*parameter/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 9, 'correct char number';


    throws_ok { sx_load '(lambda (foo 23) 7)' } E_SYNTAX, 'invalid item in lambda parameter list';
    like $@, qr/parameter list/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 14, 'correct char number';

    throws_ok { sx_load '(lambda (foo . 23) 7)' } E_SYNTAX, 'invalid item in lambda parameter list rest position';
    like $@, qr/parameter list/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 16, 'correct char number';


    throws_ok { sx_load '(lambda (foo . bar . baz) 7)' } E_SYNTAX, 'multiple dots in lambda parameter list';
    like $@, qr/dot/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 20, 'correct char number';

    throws_ok { sx_load '(lambda (foo . bar baz) 7)' } E_SYNTAX, 'multiple rest variables for lambda';
    like $@, qr/rest/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 20, 'correct char number';

    throws_ok { sx_load '(lambda (foo . ) 7)' } E_SYNTAX, 'missing rest variables for lambda';
    like $@, qr/rest/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 14, 'correct char number';


    throws_ok { sx_run '((lambda (n) n))' } E_PARAMETER, 'missing argument for defined lambda';
    like $@, qr/not enough/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 1, 'correct char number';

    throws_ok { sx_run '((lambda (n) n) 1 2)' } E_PARAMETER, 'too many arguments for defined lambda';
    like $@, qr/too many/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 1, 'correct char number';


    throws_ok { sx_load '(define (lambda bar) 7)' } E_RESERVED, 'reserved variable identifier in lambda shortcut';
    like $@, qr/reserved/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 10, 'correct char number';


    throws_ok { sx_load '(define lambda)' } E_RESERVED, 'reserved variable definition';
    like $@, qr/reserved/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 9, 'correct char number';

    throws_ok { sx_load '(define lambda 23)' } E_RESERVED, 'reserved variable definition with value';
    like $@, qr/reserved/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 9, 'correct char number';


    for my $invalid_define ('(define)', '(define foo 23 8)', '(define 23 8)', '(define 8)') {

        throws_ok { sx_load $invalid_define } E_SYNTAX, "invalid $invalid_define definition";
        like $@, qr/invalid/, 'correct error message';
        is $@->location->{line}, 1, 'correct line number';
        is $@->location->{char}, 1, 'correct char number';
    }


    for my $let_missing ('(let)', '(let*)', '(let ((x 3)))', '(let* ((x 3)))') {

        throws_ok { sx_load $let_missing } E_SYNTAX, 'let with missing arguments raises syntax error';
        like $@, qr/expect/, 'correct error message';
        is $@->location->{line}, 1, 'correct line number';
        is $@->location->{char}, 1, 'correct char number';
    }

    throws_ok { sx_load '(<-)' } E_SYNTAX, 'lambda thunk shortcut without body raises syntax error';
    like $@, qr/expression/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 1, 'correct char number';

    throws_ok { sx_load '(->)' } E_SYNTAX, 'single argument lambda shortcut without body raises syntax error';
    like $@, qr/expression/, 'correct error message';
    is $@->location->{line}, 1, 'correct line number';
    is $@->location->{char}, 1, 'correct char number';

    my @let_invalid = (

        ['let with invalid variable specification',                 '(let 23 23)',                  6, qr/variable specification.*list/],
        ['let with invalid variable specification element',         '(let (x 23) x)',               7, qr/element.*list/],
        ['let with triple as variable specification element',       '(let ((x 23 7)) x)',           7, qr/not a pair/],
        ['let with single as variable specification element',       '(let ((x)) x)',                7, qr/not a pair/],
        ['let with non-bareword as name',                           '(let ((8 x)) x)',              8, qr/not a bareword/],
        ['let with redefined vars',                                 '(let ((x 3) (x 4)) x)',       14, qr/multiple times/], 

        ['let* with invalid variable specification',                '(let* 23 23)',                 7, qr/variable specification.*list/],
        ['let* with invalid variable specification element',        '(let* (x 23) x)',              8, qr/element.*list/],
        ['let* with triple as variable specification element',      '(let* ((x 23 7)) x)',          8, qr/not a pair/],
        ['let* with single as variable specification element',      '(let* ((x)) x)',               8, qr/not a pair/],
        ['let* with non-bareword as name',                          '(let* ((8 x)) x)',             9, qr/not a bareword/],

        ['let-rec with invalid variable specification',             '(let-rec 23 23)',             10, qr/variable specification.*list/],
        ['let-rec with invalid variable specification element',     '(let-rec (x 23) x)',          11, qr/element.*list/],
        ['let-rec with triple as variable specification element',   '(let-rec ((x 23 7)) x)',      11, qr/not a pair/],
        ['let-rec with single as variable specification element',   '(let-rec ((x)) x)',           11, qr/not a pair/],
        ['let-rec with non-bareword as name',                       '(let-rec ((8 x)) x)',         12, qr/not a bareword/],
        ['let-rec with redefined vars',                             '(let-rec ((x 3) (x 4)) x)',   18, qr/multiple times/], 
    );

    for my $let_invalid (@let_invalid) {
        my ($title, $code, $char, $err) = @$let_invalid;

        throws_ok { sx_load $code } E_SYNTAX, "$title raises syntax error";
        like $@, $err, 'correct error message';
        is $@->location->{line}, 1, 'correct line number';
        is $@->location->{char}, $char, 'correct char number';
    }

}, 'ScopeHandling', 'Data::Numbers', 'Quoting', 'Data::Lists', 'Types', 'Branching');

done_testing;


