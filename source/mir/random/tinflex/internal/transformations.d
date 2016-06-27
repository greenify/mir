module mir.random.tinflex.internal.transformations;

/**
Create a c-transformation, based on a function and it's first two derivatives

Params:
    f0 = PDF function
    f1 = first derivative
    f2 = second derivative

Returns:
    Struct with the transformed functions that can be used
    to generate IntervalPoints given a specific point x
*/
template transformToInterval(S)
{
    auto transformToInterval(F0, F1, F2)(in F0 f0, in F1 f1, in F2 f2)
    {
        import mir.internal.math: pow, exp, copysign;
        import mir.random.tinflex.internal.types : IntervalPoint;

        // for c=0 no transformations are applied
        struct IP
        {
            IntervalPoint!S opCall(S x, S c) const
            {
                return IntervalPoint!S(t0(x, c), t1(x, c), t2(x, c), x, c);
            }
            S t0 (S x, S c) const
            {
                if (c == 0)
                    return f0(x);
                else
                    return copysign(S(1), c) * exp(c * f0(x));
            }
            S t1 (S x, S c) const
            {
                if (c == 0)
                    return f1(x);
                else
                    return c * t0(x, c) * f1(x);
            }
            S t2 (S x, S c) const
            {
                if (c == 0)
                    return f2(x);
                else
                    return c * t0(x, c) * (c * pow(f1(x), 2) + f2(x));
            }
        }
        IP ip;
        return ip;
    }
}

// TODO: test for c=0
// example from Tinflex
unittest
{
    import std.math: approxEqual;
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real))
    {
        auto f0 = (S x) => -x^^4 + 5 * x^^2 - 4;
        auto f1 = (S x) => 10 * x - 4 * x ^^ 3;
        auto f2 = (S x) => 10 - 12 * x ^^ 2;
        S c = 1.5;
        auto t = transformToInterval!S(f0, f1, f2);

        // magic numbers manually verified
        assert(t.t0(-3, c).approxEqual(-8.75651e-27));
        assert(t.t1(-3, c).approxEqual(-1.02451e-24));
        assert(t.t2(-3, c).approxEqual(-1.18581e-22));
    }
}

/**
Compute antiderivative FT of an inverse transformation: TF_C^-1
Table 1, column 4
*/
S antiderivative(S)(in S x, in S c)
{
    import mir.internal.math : exp, log, pow, copysign, fabs;
    if (c == 0)
        return exp(x);
    if (c == S(-0.5))
        return -1 / x;
    if (c == -1)
        return -log(-x);
    auto s = copysign(S(1), c);
    auto d = c + 1;
    auto xs = s * x;
    if(!(xs > 0))
        xs = 0;
    return fabs(c) / d * pow(xs, d / c);
}

unittest
{
    import std.math: E, approxEqual;
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real))
    {
        assert(antiderivative!S(1, 0.0).approxEqual(E));
        assert(antiderivative!S(1, -0.5) == -1);
        assert(antiderivative!S(1, -0.5) == -1);
        assert(antiderivative!S(-1, -1.0) == 0);
        assert(antiderivative!S(1, 2.0) == S(2) / 3);
    }
}

/**
Compute inverse transformation of a T_c family given point x.
From: Table 1, column 3
*/
S inverse(S)(in S x, in S c)
{
    import mir.internal.math : exp, pow, copysign;
    if (c == 0)
        return exp(x);
    if (c == S(-0.5))
        return 1 / (x*x);
    if (c == -1)
        return -1 / x;
    auto s = copysign(S(1), c);
    return pow(s * x, 1 / c);
}

unittest
{
    import std.math: E, approxEqual;
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real))
    {
        assert(inverse!S(1.0, 0).approxEqual(E));

        assert(inverse!S(2, -0.5) == 0.25);
        assert(inverse!S(8, -0.5) == 0.015625);

        assert(inverse!S(2.0, 1) == 2);
        assert(inverse!S(8.0, 1) == 8);

        assert(inverse!S(1, 1.5) == 1);
        assert(inverse!S(2, 1.5).approxEqual(1.58740));
    }
}


/**
Compute inverse transformation of antiderivative T_c family given point x.
Table 1, column 5
*/
S inverseAntiderivative(S)(in S x, in S c)
{
    import mir.internal.math : exp, log, pow, copysign, fabs;
    if (c == 0)
        return log(x);
    if (c == S(-0.5))
        return -1 / x;
    if (c == -1)
        return -exp(-x);
    auto s = copysign(S(1), c);
    auto d = c + 1;
    return s * pow(d / fabs(c) * x, c / d);
}

unittest
{
    import std.math: approxEqual, E, isNaN;
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real))
    {
        assert(inverseAntiderivative!S(1, 0).approxEqual(0));
        assert(inverseAntiderivative!S(3, 0).approxEqual(1.09861));
        assert(inverseAntiderivative!S(5.5, 0).approxEqual(1.70475));
        assert(inverseAntiderivative!S(-2, 0).isNaN);

        assert(inverseAntiderivative!S(1, -0.5) == -1);
        assert(inverseAntiderivative!S(3, -0.5) == - S(1) / 3);
        assert(inverseAntiderivative!S(-2, -0.5) == 0.5);
        assert(inverseAntiderivative!S(5.5, -0.5).approxEqual(-0.181818));
        assert(inverseAntiderivative!S(-6.3, -0.5).approxEqual(0.15873));

        assert(inverseAntiderivative!S(1, -1).approxEqual(-1 / E));
        //assert(inverseAntiderivative!S(3, -1).approxEqual(20.0855));
        //assert(inverseAntiderivative!S(-2, -1).approxEqual(0.135335));
        //assert(inverseAntiderivative!S(5.5, -1).approxEqual(244.692));
        //assert(inverseAntiderivative!S(-6.3, -1).approxEqual(0.0018363));

        assert(inverseAntiderivative!S(1, 1).approxEqual(1.41421));
        assert(inverseAntiderivative!S(3, 2).approxEqual(2.72568));
        assert(inverseAntiderivative!S(-6.3, -7).approxEqual(-7.15253));
        //assert(inverseAntiderivative!S(-2, 3.5).approxEqual(2.08461));
        //assert(inverseAntiderivative!S(5.5, -4.5).approxEqual(-6.47987));
    }
}

