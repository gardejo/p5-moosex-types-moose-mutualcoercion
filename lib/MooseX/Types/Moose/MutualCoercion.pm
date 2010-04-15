package MooseX::Types::Moose::MutualCoercion;


# ****************************************************************
# perl dependency
# ****************************************************************

use 5.008_001;


# ****************************************************************
# pragma(ta)
# ****************************************************************

# Moose turns strict/warnings pragmata on,
# however, kwalitee scorer cannot detect such mechanism.
# (Perl::Critic can it, with equivalent_modules parameter)
use strict;
use warnings;


# ****************************************************************
# general dependency(-ies)
# ****************************************************************

# use Carp qw(confess);


# ****************************************************************
# MOP dependency(-ies)
# ****************************************************************

use MooseX::Types -declare => [qw(
    NumToInt
    ScalarRefToStr      ArrayRefToLines
    StrToClassName
    StrToScalarRef
    StrToArrayRef       LinesToArrayRef
    HashRefToArrayRef   HashKeysToArrayRef  HashValuesToArrayRef
    OddArrayRef         EvenArrayRef
    ArrayRefToHashRef   ArrayRefToHashKeys
)];
use MooseX::Types::Common::String qw(
    NonEmptySimpleStr
);
use MooseX::Types::Moose qw(
    Str
        Num
            Int
        ClassName
        RoleName
    Ref
        ScalarRef
        ArrayRef
        HashRef
);


# ****************************************************************
# public class variable(s)
# ****************************************************************

our $VERSION = "0.00";


# ****************************************************************
# namespace cleaner
# ****************************************************************

use namespace::clean;


# ****************************************************************
# subtype(s) and coercion(s)
# ****************************************************************

# ================================================================
# to Int
# ================================================================

subtype NumToInt,
    as Int;

coerce NumToInt,
    from Num,
        via {
            int $_;
        };

# ================================================================
# to Str
# ================================================================

foreach my $type (
    ScalarRefToStr, ArrayRefToLines,
) {
    subtype $type,
        as Str;
}

coerce ScalarRefToStr,
    from ScalarRef[Str],
        via {
            $$_;
        };

coerce ArrayRefToLines,
    from ArrayRef[Str],
        via {
            ( join $/, @$_ ) . $/;
            # my $x = ( join $/, @$_ ) . $/;
            # warn '***', $x;
            # return $x;
        };

# ================================================================
# to ClassName
# ================================================================

subtype StrToClassName,
    as ClassName;
    # as ClassName,
    #     where {
    #         ! $_->meta->isa('Moose::Meta::Role');
    #     };

coerce StrToClassName,
    from NonEmptySimpleStr,
        via {
            _ensure_class_loaded($_);
        };

# ================================================================
# to RoleName
# ================================================================

# Fixme: Class::MOP::class_of($_)->isa('Moose::Meta::Role') is true,
#        but Class::MOP::is_loaded($_) is false (I expected it is true).
# subtype StrToRoleName,
#     as RoleName;
# 
# coerce StrToRoleName,
#     from NonEmptySimpleStr,
#         via {
#             _ensure_class_loaded($_);
#         };

# ================================================================
# to ScalarRef
# ================================================================

subtype StrToScalarRef,
    as ScalarRef[Str];

coerce StrToScalarRef,
    from Str,
        via {
            \do{ $_ };
        };

# ================================================================
# to ArrayRef
# ================================================================

foreach my $type (
    StrToArrayRef, LinesToArrayRef,
    HashRefToArrayRef, HashKeysToArrayRef, HashValuesToArrayRef,
) {
    subtype $type,
        as ArrayRef;
}

coerce StrToArrayRef,
    from Str,
        via {
            [ $_ ];
        };

coerce LinesToArrayRef,
    from Str,
        via {
            ( my $new_line = $/ ) =~ s{(.)}{[$1]}xmsg;
            [ split m{ (?<= $new_line ) }xms, $_ ];
        };

coerce HashRefToArrayRef,
    from HashRef,
        via {
            my $hashref = $_;
            [
                map {
                    $_, $hashref->{$_};
                } sort keys %$hashref
            ];
        };

coerce HashKeysToArrayRef,
    from HashRef,
        via {
            [ sort keys %$_ ];
        };

coerce HashValuesToArrayRef,
    from HashRef,
        via {
            my $hashref = $_;
            [
                map {
                    $hashref->{$_};
                } sort keys %$hashref
            ];
        };

subtype OddArrayRef,
    as ArrayRef,
        where {
            scalar @$_ % 2;
        };

subtype EvenArrayRef,
    as ArrayRef,
        where {
            ! scalar @$_ % 2;
        };

foreach my $type (OddArrayRef, EvenArrayRef) {
    coerce $type,
        from ArrayRef,
            via {
                push @$_, undef;
                $_;
            };
}


# ================================================================
# to HashRef
# ================================================================

foreach my $type (
    ArrayRefToHashRef, ArrayRefToHashKeys,
) {
    subtype $type,
        as HashRef;
}

coerce ArrayRefToHashRef,
    from EvenArrayRef,
        via {
            # confess 'Odd number of elements in hash assignment'
            #     if @$_ % 2;
            my %hash = @$_;     # Note: "{ @$_ }" does not run (need "return")
            \%hash;
        };

coerce ArrayRefToHashKeys,
    from EvenArrayRef,
        via {
            my %hash = @$_;
            @hash{keys %hash} = ();
            \%hash;
        };


# ****************************************************************
# subroutine(s)
# ****************************************************************

sub _ensure_class_loaded {
    my $class = shift;

    # Fixme: I cannot load role by Class::MOP::load_class($class).
    #        Perhaps role must be consumed by some class?
    Class::MOP::load_class($class)
        unless Class::MOP::is_class_loaded($class);

    return $class;
}


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=pod

=head1 NAME

MooseX::Types::Moose::MutualCoercion - Mutual coercions for common type constraints of Moose

=head1 SYNOPSIS

    {
        package Foo;
        use Moose;
        use MooseX::Types::Moose::MutualCoercion qw(
            StrToArrayRef ArrayRefToHashRef
        );
        has 'tags'
            => ( is => 'rw', isa => StrToArrayRef, coerce => 1 );
        has 'lookup_table'
            => ( is => 'rw', isa => ArrayRefToHashRef, coerce => 1 );
        1;
    }
    {
        package main;
        my $foo = Foo->new(
            tags         => 'bar',
            lookup_table => [qw(baz qux)],
        );
        print $foo->tags->[0];      # 'bar'
        print 'eureka!'             # 'eureka!'
            if grep {
                exists $foo->lookup_table->{$_};
            } qw(foo bar baz);
    }

=head1 DESCRIPTION

This module packages several
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints> with coercions,
designed to mutually coerce with the built-in or common types
known to L<Moose|Moose>.

=head1 CONSTRAINTS AND COERCIONS

=head2 To C<Int>

=over 4

=item C<NumToInt>

A subtype of C<Int>.
If you turned C<coerce> on, C<Num> will be integer.
For example, C<3.14> will be converted into C<3>.

=back

=head2 To C<Str>

=over 4

=item C<ScalarRefToStr>

A subtype of C<Str>.
If you turned C<coerce> on, C<ScalarRef[Str]> will be dereferenced string.
For example, C<\do{'foo'}> will be converted into C<foo>.

=item C<ArrayRefToLines>

A subtype of C<Str>.
If you turned C<coerce> on,
all elements of C<ArrayRef[Str]> will be joined by C<$/>.
For example, C<[qw(foo bar baz)]> will be converted into C<foo\nbar\nbaz\n>.

=back

=head2 To C<ClasName>

=over 4

=item C<StrToClassName>

A subtype of C<ClassName>.
If you turned C<coerce> on, C<NonEmptySimpleStr>, provided by
L<MooseX::Types::Common::String|MooseX::Types::Common::String>,
will be ensure loaded by L<Class::MOP::load_class()|Class::MOP>.

B<CAVEAT>: This module does not provide C<StrToRoleName> currentry.

=back

=head2 To C<ScalarRef>

=over 4

=item C<StrToScalarRef>

A subtype of C<ScalarRef>.
If you turned C<coerce> on, C<Str> will be referenced.
For example, C<foo> will be converted into C<\do{'foo'}>.

=back

=head2 To C<ArrayRef>

=over 4

=item C<StrToArrayRef>

A subtype of C<ArrayRef>.
If you turned C<coerce> on, C<Str> will be assined for the first element
of an array reference.
For example, C<foo> will be converted into C<[qw(foo)]>.

=item C<LinesToArrayRef>

A subtype of C<ArrayRef>.
If you turned C<coerce> on, C<Str> will be split by C<$/>
and will be assigned for each element of an array reference.
For example, C<foo\nbar\nbaz> will be converted into C<[qw(foo bar baz)]>.

=item C<HashRefToArrayRef>

A subtype of C<ArrayRef>.
If you turned C<coerce> on, C<HashRef> will be a flatten array reference.
For example, C<{foo => 0, bar => 1}>
will be converted into C<[qw(foo 0 bar 1)]>.

=item C<HashKeysToArrayRef>

A subtype of C<ArrayRef>.
If you turned C<coerce> on,
lexically sorted keys of C<HashRef> will be a flatten array reference.
For example, C<{foo => 0, bar => 1}>
will be converted into C<[qw(foo bar)]>.

=item C<HashValuesToArrayRef>

A subtype of C<ArrayRef>.
If you turned C<coerce> on,
values of C<HashRef> will be a flatten array reference.
For example, C<{foo => 1, bar => 0}>
will be converted into C<[qw(0 1)]>.

B<NOTE>: Order of values is the same as lexically sorted keys.

=item C<OddArrayRef>

A subtype of C<ArrayRef>, that must have odd elements.
If you turned C<coerce> on, C<ArrayRef>, that has even elements,
was pushed C<undef> as the last element.
For example, C<[qw(foo bar)]> will be converted into C<[qw(foo bar), undef]>.

=item C<EvenArrayRef>

A subtype of C<ArrayRef>, that must have even elements.
If you turned C<coerce> on, C<ArrayRef>, that has odd elements,
was pushed C<undef> as the last element.
For example, C<[qw(foo)]> will be converted into C<[qw(foo), undef]>.

=back

=head2 To C<HashRef>

=over 4

=item C<ArrayRefToHashRef>

A subtype of C<HashRef>.
If you turned C<coerce> on,
all elements of C<EvenArrayRef> was substituted for a hash reference.
For example, C<[foo 0 bar 1]>
will be converted into C<{foo => 0, bar => 1}>.

=item C<ArrayRefToHashKeys>

A subtype of C<HashRef>.
If you turned C<coerce> on,
all elements of C<ArrayRef> was substituted for keys of a hash reference.
For example, C<[foo bar baz]>
will be converted into C<{foo => undef, bar => undef, baz => undef}>.

=back

=head1 SEE ALSO

=over 4

=item *

L<MooseX::Types|MooseX::Types>

=item *

L<MooseX::Types::Moose|MooseX::Types::Moose>

=item *

L<MooseX::Types::Common|MooseX::Types::Common>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 TO DO

=over 4

=item *

More tests

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head2 Making suggestions and reporting bugs

Please report any found bugs, feature requests, and ideas for improvements
to C<bug-moosex-types-moose-mutualcoercion at rt.cpan.org>,
or through the web interface
at L<http://rt.cpan.org/Public/Bug/Report.html?Queue=MooseX-Types-Moose-MutualCoercion>.
I will be notified, and then you'll automatically be notified of progress
on your bugs/requests as I make changes.

When reporting bugs, if possible,
please add as small a sample as you can make of the code
that produces the bug.
And of course, suggestions and patches are welcome.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc MooseX::Types::Moose::MutualCoercion

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-Moose-MutualCoercion>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Types-Moose-MutualCoercion>

=item Search CPAN

L<http://search.cpan.org/dist/MooseX-Types-Moose-MutualCoercion>

=item CPAN Ratings

L<http://cpanratings.perl.org/dist/MooseX-Types-Moose-MutualCoercion>

=back

=head1 VERSION CONTROL

This module is maintained using I<git>.
You can get the latest version from
L<git://github.com/gardejo/p5-moosex-types-moose-mutualcoercion.git>.

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 MORIYA Masaki, alias Gardejo

This library is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
