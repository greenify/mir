module mir.compat.meta;

static if (__traits(compiles, { import std.meta; }))
    public import std.meta;
else
{
    public import std.typetuple;
    alias AliasSeq = TypeTuple;
}

