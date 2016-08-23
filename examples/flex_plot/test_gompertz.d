#!/usr/bin/env dub
/+ dub.sdl:
name "flex_plot_test_gompertz"
dependency "flex_common" path="./flex_common"
versions "Flex_logging" "Flex_single"
+/

/**
Gompertz distribution for b = 1.5 and n = 0.005

See_Also:
    $(LINK2 https://en.wikipedia.org/wiki/Gompertz_distribution, Wikipedia)
*/
void test(S, F)(in ref F test)
{
    import std.math : exp, log;

    auto f0 = (S x) => cast(S) log( S(0.00753759) * exp(S(-0.005) * exp(S(1.5) * x) + S(1.5) * x));
    auto f1 = (S x) => S(1.5) - S(0.0075) * exp(1.5 * x);
    auto f2 = (S x) => S(-0.01125) * exp(S(1.5) * x);


    S[] points = [0, 6, 10, S.max];
    test.plot("dist_gompertz", f0, f1, f2, 0.5, points, 0, 6);
}

version(Flex_single) void main()
{
    import flex_common;
    alias T = double;
    auto cf = CFlex!T(20_000, "plots", 1.1, true, true);
    cf.plotTitle = false;
    test!T(cf);
}
