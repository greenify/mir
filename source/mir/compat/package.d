module mir.compat;

import mir.compat.meta;

enum hasPragmaInline = __traits(compiles, { pragma(inline, true); });

static import std.traits;
static if (__traits(hasMember, std.traits, "hasUDA"))
    alias hasUDA = std.traits.hasUDA;
else
{
    /**
     * Determine if a symbol has a given $(LINK2 ../attribute.html#uda, user-defined attribute).
     */
    template hasUDA(alias symbol, alias attribute)
    {
        import std.typetuple : staticIndexOf;

        static if (is(attribute == struct) || is(attribute == class))
        {
            template GetTypeOrExp(alias S)
            {
                static if (is(typeof(S)))
                    alias GetTypeOrExp = typeof(S);
                else
                    alias GetTypeOrExp = S;
            }
            enum bool hasUDA = staticIndexOf!(attribute, staticMap!(GetTypeOrExp,
                    __traits(getAttributes, symbol))) != -1;
        }
        else
            enum bool hasUDA = staticIndexOf!(attribute, __traits(getAttributes, symbol)) != -1;
    }

    ///
    unittest
    {
        enum E;
        struct S;
        struct Named { string name; }

        @("alpha") int a;
        static assert(hasUDA!(a, "alpha"));
        static assert(!hasUDA!(a, S));
        static assert(!hasUDA!(a, E));

        @(E) int b;
        static assert(!hasUDA!(b, "alpha"));
        static assert(!hasUDA!(b, S));
        static assert(hasUDA!(b, E));

        @E int c;
        static assert(!hasUDA!(c, "alpha"));
        static assert(!hasUDA!(c, S));
        static assert(hasUDA!(c, E));

        @(S, E) int d;
        static assert(!hasUDA!(d, "alpha"));
        static assert(hasUDA!(d, S));
        static assert(hasUDA!(d, E));

        @S int e;
        static assert(!hasUDA!(e, "alpha"));
        static assert(hasUDA!(e, S));
        static assert(!hasUDA!(e, E));

        @(S, E, "alpha") int f;
        static assert(hasUDA!(f, "alpha"));
        static assert(hasUDA!(f, S));
        static assert(hasUDA!(f, E));

        @(100) int g;
        static assert(hasUDA!(g, 100));

        @Named("abc") int h;
        static assert(hasUDA!(h, Named));
    }
}
