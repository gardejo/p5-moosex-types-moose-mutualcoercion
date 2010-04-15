use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

our @TYPE_NAMES;
BEGIN {
    @TYPE_NAMES = qw(
        NumToInt
        ScalarRefToStr      ArrayRefToLines
        StrToClassName
        StrToScalarRef
        StrToArrayRef       LinesToArrayRef
        HashRefToArrayRef   HashKeysToArrayRef  HashValuesToArrayRef
        OddArrayRef         EvenArrayRef
        ArrayRefToHashRef   ArrayRefToHashKeys
    );
}

{
    package Foo;
    use namespace::autoclean;
    use Moose;

    use MooseX::Types::Moose::MutualCoercion (@TYPE_NAMES);

    my @cliche = (is => 'rw', coerce => 1, 'isa');

    has numtoint             => ( @cliche, NumToInt );
    has scalarreftostr       => ( @cliche, ScalarRefToStr );
    has arrayreftolines      => ( @cliche, ArrayRefToLines );
    has strtoclassname       => ( @cliche, StrToClassName );
    has strtoscalarref       => ( @cliche, StrToScalarRef );
    has strtoarrayref        => ( @cliche, StrToArrayRef );
    has linestoarrayref      => ( @cliche, LinesToArrayRef );
    has hashreftoarrayref    => ( @cliche, HashRefToArrayRef );
    has hashkeystoarrayref   => ( @cliche, HashKeysToArrayRef );
    has hashvaluestoarrayref => ( @cliche, HashValuesToArrayRef );
    has oddarrayref          => ( @cliche, OddArrayRef );
    has evenarrayref         => ( @cliche, EvenArrayRef );
    has arrayreftohashref    => ( @cliche, ArrayRefToHashRef );
    has arrayreftohashkeys   => ( @cliche, ArrayRefToHashKeys );

    __PACKAGE__->meta->make_immutable;
    1;
}
{
    use Test::More;
    use Test::Exception;

    my ($number_of_skipping_types, $number_of_begin_block_tests);

    BEGIN {
        $number_of_skipping_types    = 1;   # StrToRoleName
        $number_of_begin_block_tests = 1;   # use_ok
        plan tests => scalar @TYPE_NAMES
                    + $number_of_skipping_types
                    + $number_of_begin_block_tests;
        use_ok( 'MooseX::Types::Moose::MutualCoercion' );
    }

    my $foo = Foo->new;

    is(
        $foo->numtoint(3.14),
        3,
        'coercion of NumToInt'
    );
    is_deeply(
        $foo->scalarreftostr(\do{ 'foo' }),
        'foo',
        'coercion of ScalarRefToStr'
    );
    is(
        $foo->arrayreftolines([qw(foo bar baz qux)]),
        "foo\nbar\nbaz\nqux\n",
        'coercion of ArrayRefToLines'
    );
    is(
        $foo->strtoclassname('Test::SomeClass'),
        'Test::SomeClass',
        'coercion of StrToClassName'
    );
    SKIP: {
        skip(
            'cannot load a role by Class::MOP::load_class',
            $number_of_skipping_types
        );
        is(
            $foo->strtorolename('Test::SomeRole'),
            'Test::SomeRole',
            'coercion of StrToRoleName'
        );
    };
    is_deeply(
        $foo->strtoscalarref('foo'),
        \'foo',
        'coercion of StrToScalarRef'
    );
    is_deeply(
        $foo->strtoarrayref('element0'),
        [qw(element0)],
        'coercion of StrToArrayRef' );
    is_deeply(
        $foo->linestoarrayref("element0\nelement1\nelement2\n"),
        [("element0\n", "element1\n", "element2\n")],
        'coercion of LinesToArrayRef'
    );
    is_deeply(
        $foo->hashreftoarrayref({ a => 0, b => 1, c => 2 }),
        [qw(a 0 b 1 c 2)],
        'coercion of HashRefToArrayRef'
    );
    is_deeply(
        $foo->hashkeystoarrayref({ d => 3, e => 4, f => 5 }),
        [qw(d e f)],
        'coercion of HashKeysToArrayRef'
    );
    is_deeply(
        $foo->hashvaluestoarrayref({ g => 8, h => 7, i => 6 }),
        [qw(8 7 6)],
        'coercion of HashValuesToArrayRef'
    );
    is_deeply(
        $foo->oddarrayref([qw(element0 element1)]),
        [qw(element0 element1), undef],
        'coercion of OddArrayRef'
    );
    is_deeply(
        $foo->evenarrayref([qw(element0 element1 element2)]),
        [qw(element0 element1 element2), undef],
        'coercion of EvenArrayRef'
    );
    is_deeply(
        $foo->arrayreftohashref([qw(j  9 k 10 l 11)]),
        { j => 9, k => 10, l => 11, },
        'coercion of ArrayRefToHashRef'
    );
    is_deeply(
        $foo->arrayreftohashkeys([qw(m 12 n 13 o 14)]),
        { m => undef, n => undef, o => undef, },
        'coercion of ArrayRefToHashKeys'
    );
}

__END__
