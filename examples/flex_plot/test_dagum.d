#!/usr/bin/env dub
/+ dub.sdl:
name "flex_plot_test_dagum"
dependency "flex_common" path="./flex_common"
versions "Flex_logging" "Flex_single"
+/

/**
Dagum distribution for a = 1, b = 1, p = 1

See_Also:
    $(LINK2 https://en.wikipedia.org/wiki/Dagum_distribution, Wikipedia)
*/
void test(S, F)(in ref F test)
{
    import std.math : log;

    auto f0 = (S x) => cast(S) log(1/(x+1)^^2);
    auto f1 = (S x) => -2/(1 + x);
    auto f2 = (S x) => 2/(1 + x)^^2;
    S[] points = [0, 6, S.max];
    test.plot("dist_dagum", f0, f1, f2, 0.5, points, 0, 3);
}

version(Flex_single) void main()
{
    import flex_common;
    alias T = double;
    auto cf = CFlex!T(20_000, "plots", 1.1, true, true);
    cf.plotTitle = false;
    test!T(cf);
}
