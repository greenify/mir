/**
Random utilities.
*/

module mir.random.tinflex.internal.random;

/**
Convenience method to sample Arrays with sample r
This will be replaced with a more sophisticated version in later versions.

Params:
    r = random sampler
    n = number of times to sample
Returns: Randomly sampled Array of length n
*/
typeof(R.init())[] sample(R, RNG)(R r, int n, RNG rnd)
{
    alias S = typeof(r());
    S[] arr = new S[n];
    foreach (ref s; arr)
        s = r(rnd);
    return arr;
}

/// ditto
typeof(R.init())[] sample(R, RNG)(R r, int n)
{
    import std.random : rndGen;
    return sample(r, n, rndGen);
}
