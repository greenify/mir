
import std.traits: isAssignable, isFloatingPoint;

/**
Checks whether we can do basic arithmetic operations, comparisons and
assign values to the type.
*/
private template isArithmetic(R)
{
    enum bool isArithmetic = is(typeof(
    (inout int = 0)
    {
        R test = R.init * R.init / R.init + R.init - R.init;
        if(R.init < R.init) {}
        if(R.init > R.init) {}
    }));
}

/**
Checks whether we can do basic arithmetic operations between two types
*/
private template isArithmetic(R, S)
{
    enum bool isArithmetic = is(typeof(
    (inout int = 0)
    {
        R test = R.init * S.init + S.init * R.init;
        //S test = R.init / S.init + S.init / R.init;
        //R test = R.init + S.init;
        //R test = R.init + S.init + S.init + R.init;
        //S test = R.init - S.init + S.init - R.init;
        //if(R.init < R.init && R.init > R.init) {}
    }));
}

/**
Computes the $(WEB en.wikipedia.org/wiki/Factorial, factorial) of n -
also written as `n!`. It is the product of all positive integeres less than or
equal n. Its generalization to real numbers is called the Gamma function.
As the factorial grows very quickly, it is recommended to use `BigInt`.

Params:
    n = factorial number

Returns:
    Computed factorial
*/
auto factorial(R, T)(T n)
{
    static if (isFloatingPoint!R)
    {
        import std.mathspecial: gamma;
        return gamma(n+1);
    }
    else static if (is(R == uint) || is(R == int))
    {
        // all integer values (0-12)
        if(0 <= n && n < 13)
        {
            static immutable res = [1, 1, 2, 6, 24, 120, 720, 5040, 40320,
                362880, 3628800, 39916800, 479001600];
            return res[n];
        }
    }
    else static if (is(R == ulong) || is(R == long))
    {
        // all long values 0-20
        if (0 <= n && n < 21)
        {
            static immutable res = [1, 1, 2, 6, 24, 120, 720, 5040, 40320,
                362880, 3628800, 39916800, 479001600, 6227020800, 87178291200,
                1307674368000, 20922789888000, 355687428096000, 6402373705728000,
                121645100408832000, 2432902008176640000];
            return res[n];
        }
    }
    else
    {
        if(n > 19)
        {
            R result = factorial!ulong(20);
            T target = n + 1;
            for (T i = 21; i < target;i++)
            {
                result *= i;
            }
            return result;
        }
        else if(n >= 0)
        {
            R result = factorial!ulong(n);
            return result;
        }
    }
    //assert(0, "negative numbers are not defined");
    static if (!isFloatingPoint!R)
    {
        R result = 0;
        return result;
    }
}

// convenience overload if target has the same type
/// ditto
auto factorial(T)(T n)
{
    return factorial!(T, T)(n);
}

unittest
{
    assert(factorial(0) == 1);
    assert(factorial(1) == 1);
    assert(factorial(2) == 2);
    assert(factorial(10) == 3628800);
    assert(factorial!ulong(20) == 2432902008176640000);

    import std.bigint;
    assert(factorial!BigInt(30) == BigInt("265252859812191058636308480000000"));
}

unittest
{
    import std.bigint;
    assert(factorial!BigInt(0) == 1);
    assert(factorial!BigInt(1) == 1);
    assert(factorial!BigInt(10) == 3628800);

    // floating point
    import std.math: approxEqual;
    assert(factorial(5.5).approxEqual(287.885, 0.001));
    assert(factorial!float(5.5).approxEqual(287.885, 0.001));
    assert(factorial!real(5.5).approxEqual(287.885, 0.001));
}

/**
Computes the $(WEB mathworld.wolfram.com/RisingFactorial.html, rising factorial)
starting from `x` upwards for `n` values to `x + n - 1`. It is also known as
$(WEB en.wikipedia.org/wiki/Pochhammer_symbol Pochhammer symbol),
Pochhammer function, ascending factorial, rising sequential product or
upper factorial.

Params:
    x = starting number of the rising factorial
    n = number of iterations of the rising factorial

Returns:
    Computed rising factorial
*/
auto rfactorial(R, T)(T x, T n)
{
    static if (isFloatingPoint!T)
    {
        import std.mathspecial: gamma;
        return gamma(x + n) / gamma(x);
    }
    else
    {
        return binomial!(R, T)(x + n -1, n) * factorial!(R, T)(n);
    }
}

/// ditto
auto rfactorial(T)(T x, T n)
{
    return rfactorial!(T, T)(x, n);
}

///
unittest
{
    assert(rfactorial(2, 1) == 2);
    assert(rfactorial(4, 5) == 6720);
    assert(rfactorial(3, 10) == 239500800);
    assert(rfactorial(-4, 10) == 0);
    assert(rfactorial(3, 0) == 1);
    assert(rfactorial(-5, 2) == 20);

    import std.bigint;
    assert(rfactorial!BigInt(5, 30) == BigInt("12301366626650172535317442068480000000"));

    import std.math: approxEqual;
    assert(rfactorial(3.5, 0.5).approxEqual(1.80541, 0.001));
    assert(rfactorial(4.3, 12.45).approxEqual(1.17450e12, 0.001));
    assert(rfactorial(5.5, -1.2).approxEqual(0.169180, 0.00001));
    assert(rfactorial(-4.7, -1.2).approxEqual(-0.317794, 0.001));
    assert(rfactorial(-4.7, 1.2).approxEqual(-5.04449, 0.001));

    // TODO: fix accuracy
    //assert(rfactorial(-5, -3).approxEqual(-0.00297619, 0.001));
}

/**
Computes the $(WEB mathworld.wolfram.com/FallingFactorial.html, falling factorial)
starting from `x` downwards for `n` values to `x - n + 1`. It is also known as
descending factorial, falling sequential product or lower factorial.

Params:
    x = starting number of the falling factorial
    n = number of iterations of the falling factorial

Returns:
    Computed falling factorial
*/
auto ffactorial(R, T)(T x, T n)
{
    //return (n & 1 ? -1 : 1) * rfactorial!(R, X, T)(x, n);
    return binomial!(R, T)(x, n) * factorial!(R, T)(n);
}

auto ffactorial(T)(T x, T n)
{
    return ffactorial!(T, T)(x, n);
}

///
unittest
{
    assert(ffactorial(2, 1) == 2);
    assert(ffactorial(4, 5) == 0);
    assert(ffactorial(4, 3) == 24);
    assert(ffactorial(7, 2) == 42);
    assert(ffactorial(3, 0) == 1);
    assert(ffactorial(3, 1) == 3);
    assert(ffactorial(5, 30) == 0);
    assert(ffactorial(-7, 3) == -504);
    assert(ffactorial(-5, 2) == 30);
    assert(ffactorial(-7, 2) == 56);

    import std.bigint;
    assert(ffactorial!BigInt(30, 30) == BigInt("265252859812191058636308480000000"));
    assert(ffactorial!BigInt(-5, 30) == BigInt("12301366626650172535317442068480000000"));

    import std.math: approxEqual;
    assert(ffactorial(3.5, 0.5).approxEqual(1.93862, 0.001));
    assert(ffactorial(4.3, 12.45).approxEqual(37579.8, 0.001));
    assert(ffactorial(-4.7, -1.2).approxEqual(-0.26620297, 0.001));

    // TODO: fix accuracy
    //assert(ffactorial(5.5, -1.2).approxEqual(0.103936, 0.00001));
    //assert(ffactorial(-4.7, 1.2).approxEqual(-2.50669, 0.001));
    //assert(ffactorial(-5, -3).approxEqual(-0.0416666, 0.0001));
}

/**
Computes the $(WEB https://en.wikipedia.org/wiki/Motzkin_number, Catalan number)

Params:
    n = Catalan number (n points on the circle)

References:
    Stanley, Richard and Weisstein, Eric W. "Catalan Number." From MathWorld
    $(WEB http://mathworld.wolfram.com/CatalanNumber.html, MathWorld)
*/
R catalan(R = ulong, T)(T n)
if (isArithmetic!(R, T))
{
    return binomial!R(2 * n, n) / (n + 1);
}

///
pure unittest
{
    assert(catalan(0) == 1);
    assert(catalan(1) == 1);
    assert(catalan(2) == 2);

    import std.bigint;
    assert(catalan!BigInt(50) == BigInt("1978261657756160653623774456"));
}

pure nothrow @safe @nogc unittest
{
    assert(catalan(3) == 5);
    assert(catalan(30) == 3814986502092304);
}

/**
Computes the $(WEB https://en.wikipedia.org/wiki/Motzkin_number, Motzkin number)
of n.
It is the number of different ways of drawing non-intersecting chords
between n points on a circle.

Params:
    n = Motzkin number (n points on the circle)

References:
Weisstein, Eric W. "Motzkin Number." From
$(WEB mathworld.wolfram.com/MotzkinNumber.html, MathWorld)
*/
T motzkin(T = ulong, R)(R n)
//if (isArithmetic!(R, T))
{
    import std.traits: isIntegral;
    static if(isIntegral!R)
        R t = n / 2;
    else
    {
        import std.math: floor;
        R t = floor(n / 2);
    }
    T result = 0;
    for(R k = 0; k <= t; k++)
    {
       result += binomial(n, 2 * k) * catalan(k);
    }
    return result;
}

pure unittest
{
    import std.stdio;
    assert(motzkin(0) == 1);
    assert(motzkin(1) == 1);
    assert(motzkin(2) == 2);
    assert(motzkin(10) == 2188);

    import std.bigint;
    assert(motzkin!BigInt(50) == BigInt("125537377874009938026"));
}


