module mir.random.tinflex.internal.area;

import mir.random.tinflex.internal.types : IntervalPoint;
import mir.random.tinflex.internal.linearfun : LinearFun;
import std.traits : ReturnType;

protected:

/**
Tuple of hat and squeeze function.
*/
struct HatAndSqueeze(S)
{
    LinearFun!S hat, squeeze;
}

/**
Determines the hat and squeeze function of an interval.
Based on Theorem 1
*/
HatAndSqueeze!S determineHatAndSqueeze(S)(in IntervalPoint!S l, in IntervalPoint!S r)
{
    import mir.random.tinflex.internal.linearfun : secant, tangent;
    import mir.random.tinflex.internal.types : determineType, FunType;

    enum sec = "secant(l.x, r.x, l.tx, r.tx)";
    enum t_l = "tangent(l.x, l.tx, l.t1x)";
    enum t_r = "tangent(r.x, r.tx, r.t1x)";

    // t_m is t_l or t_r wherever f(x) larger
    enum t_m = "(l.tx > r.tx) ? " ~ t_l ~ " : " ~ t_r;

    LinearFun!S hat;
    LinearFun!S squeeze;

    // could potentially be saved for subsequent calls
    FunType type = determineType(l, r);

    with(FunType)
    final switch(type)
    {
        // concave near b_l and t_r(x) <= f(x) <= t_l(x)
        case T1a:
            squeeze = mixin(t_r);
            hat = mixin(t_l);
            break;

        // convex near b_l and t_l(x) <= f(x) <= t_r(x)
        case T1b:
            squeeze = mixin(t_l);
            hat = mixin(t_r);
            break;

        // concave near b_l and r(x) <= f(x) <= t_l(x)
        case T2a:
            squeeze = mixin(sec);
            hat = mixin(t_l);
            break;

        // convex near b_l and r(x) <= f(x) <= mixin(t_r)(x)
        case T2b:
            squeeze = mixin(sec);
            hat = mixin(t_r);
            break;

        // concave near b_l and mixin(t_r)(x) <= f(x) <= r(x)
        case T3a:
            squeeze = mixin(t_r);
            hat = mixin(sec);
            break;

        // convex near b_l and mixin(t_l)(x) <= f(x) <= r(x)
        case T3b:
            squeeze = mixin(t_l);
            hat = mixin(sec);
            break;

        // concave on [b_l, b_r] and r(x) <= f(x) <= mixin(t_m)(x)
        case T4a:
            squeeze = mixin(sec);
            hat = mixin(t_m);
            break;

        // convex on [b_l, b_r] and t_m(x) <= f(x) <= r(x)
        case T4b:
            squeeze = mixin(t_m);
            hat = mixin(sec);
            break;
    }
    return HatAndSqueeze!S(hat, squeeze);
}

// TODO: add more tests
unittest
{
    import std.meta : AliasSeq;
    import mir.random.tinflex.internal.types: determineType;
    import mir.random.tinflex.internal.linearfun : linearFun;
    foreach (S; AliasSeq!(float, double, real))
    {
        const f0 = (S x) => x * x;
        const f1 = (S x) => 2 * x;
        const f2 = (S x) => 2.0;
        auto c = 42; // not required for this test
        auto dhs = (S l, S r) => determineHatAndSqueeze(IntervalPoint!S(f0(l), f1(l), f2(l), l, c),
                                                        IntervalPoint!S(f0(r), f1(r), f2(r), r, c));

        // test left side
        auto hs1 = dhs(-1, 1);
        assert(hs1.hat == linearFun!S(0.0, 1));
        assert(hs1.squeeze == linearFun!S(2.0, -1));

        // test right side
        auto hs2 = dhs(1, 3);
        assert(hs2.hat == linearFun!S(4.0, -3));
        assert(hs2.squeeze == linearFun!S(6.0, -9));
    }
}

/**
Computes the area below a function sh in-between l and r.
Based on table 1 and general equation (3) from the Tinflex paper

    (F_T(sh(r))- F_T(sh(l))) / sh.slope

Params:
    sh = linear function
    l  = start of interval
    r  = end of interval
    ly = start of interval (y-value)
    ry = end of interval (y-value)
    c  =  interval type (see paper)

Returns: Computed area below sh.
*/
S area(S)(in LinearFun!S sh, in S l, in S r, in S ly, in S ry, in S c)
out (result)
{
    import std.math : isNaN;
    assert(!isNaN(result), "Computed area can't be NaN");
}
body
{
    import mir.internal.math: copysign, exp, log;
    import std.math: abs, sgn;
    import mir.random.tinflex.internal.transformations : antiderivative, inverse;

    S area = void;
    // check difference to left and right starting point
    const byte leftOrRight = (l - sh._y) > (sh._y - r) ? 1 : -1;

    // sh.y is the boundary point where f obtains its maximum

    // specializations for T_c family (page 6)
    if (c == 0)
    {
        // T_c = log(x)
        // Error in table, see equation (4)
        immutable z = leftOrRight * sh.slope * (r - l);
        // check whether approximation is possible, page 5
        if (abs(z) < 1e-6)
        {
            area = exp(sh._y) * (r - l) * (1 + z / 2 + (z^^2) / 6);
        }
        else
        {
            // F_T = e^x
            area = (exp(sh(r)) - exp(sh(l))) / sh.slope;
        }
    }
    else
    {
        // for c < 0, the tangent result must result in a valid (bounded) hat function
        if (copysign(sh(r), c) < 0 || copysign(sh(l), c) < 0)
        {
            // returning infinity will yield a split on this interval.
            return S.infinity;
        }

        immutable z = leftOrRight / sh.a * sh.slope * (r - l);

        if (c == 1)
        {
            // T_c^-1 = x^c
            area = 0.5  * sh._y * (r - l) * (2 + z);
        }
        else if (c == -0.5)
        {
            // T_c = -1/sqrt(x)
            if (abs(z) < 0.5)
            {
                // T_c^-1 = 1/x^2
                area = 1 / (sh._y ^^ sh._y) * (1 - z + z ^^ 2);
            }
            else
            {
                area = (-1 / sh(l)) + (1 / sh(r));
            }
        }
        else if (c == -1)
        {
            // T_C = -1 / x
            if (abs(z) < 1e-6)
            {
                // T_C^-1 = -1 / x
                area = -1 / sh._y * (r - l) * (1 - z / 2 + z^^2 / 3);
            }
            else
            {
                // F_T = -log(-x)
                area = -log(-sh(r)) + log(-sh(l));
            }
        }
        else
        {
            // T_c = -1 / x
            //area = (r - l) * c / (c + 1) * 1 / z * ((1 + z)^^((c + 1) / c) - 1);
            if (abs(sh.slope) > 1e-10)
            {
                alias ad = antiderivative;
                area = (ad(sh(r), c) - ad(sh(l), c)) / sh.slope;
            }
            else
            {
                area = inverse(sh.a, c) * (r - l);
            }
        }
    }
    import std.math : isInfinity, isNaN;
    if (isInfinity(area) || isNaN(area))
        return 0.0;
    else
        return area;
}

// example from Tinflex
unittest
{
    import mir.random.tinflex.internal.transformations : transformToInterval;
    import mir.random.tinflex.internal.types : determineType;
    import std.math: approxEqual;
    import std.meta : AliasSeq;
    import std.range: dropOne, lockstep, save;

    enum rho = 1.1;

    // inflection points: -1.7620, -1.4012, 1.4012, 1.7620
    enum points = [-3.0, -1.5, 0.0, 1.5, 3];
    enum hats = [25.438585, 8.022358, 8.022358, 25.438585];
    enum sqs = [0, 0.027473, 0.027473, 0];

    foreach (S; AliasSeq!(float, double, real))
    {
        const f0 = (S x) => -x^^4 + 5 * x^^2 - 4;
        const f1 = (S x) => 10 * x - 4 * x ^^ 3;
        const f2 = (S x) => 10 - 12 * x ^^ 2;
        S c = 1.5;

        auto intervalTransform = transformToInterval!S(f0, f1, f2);

        // calculate the area of all intervals
        foreach (i, p1, p2; points.lockstep(points.save.dropOne))
        {
            auto s1 = intervalTransform(p1, c);
            auto s2 = intervalTransform(p2, c);
            auto sh = determineHatAndSqueeze(s1, s2);

            auto aHat = area(sh.hat, s1.x, s2.x, s1.tx, s2.tx, c);
            assert(aHat.approxEqual(hats[i]));

            auto aSqueeze = area(sh.squeeze, s1.x, s2.x, s1.tx, s2.tx, c);
            assert(aSqueeze.approxEqual(sqs[i]));
        }
    }
}
