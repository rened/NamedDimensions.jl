module NamedDimensions
using FunctionalData

export named, array, names
type NamedDims{N}
    data
    names
    function NamedDims(a, names...)
        names = collect(names)
        assert(length(names) <= ndims(a))
        if length(names) < ndims(a)
            names = vcat([Symbol("dim$i") for i in 1:ndims(a)-length(names)], names)
        end
        new(a, names)
    end
end

named(a::AbstractArray, names...) = (assert(all(x->isa(x,Symbol), names)); NamedDims{ndims(a)}(a, names...))
array(a::NamedDims) = a.data
array(a::NamedDims, inds...) = array(named(a, inds...))
import Base.getindex
getindex(a::NamedDims, inds...) = array(a, inds...)
at(a::NamedDims, inds...) = array(a, inds...)
call(a::NamedDims, inds...) = named(a, inds...)

names(a::NamedDims) = a.names

inside = in
function named(a::NamedDims, inds...)
    isname(x) = (isa(x, Pair) && isa(x.first, Symbol)) || isa(x, Symbol)
    issqueezer(x) = isa(x, Pair) && isa(x.second, Integer)
    if all(x->!isa(x, Pair), inds) && any(x->!isa(x, Symbol), inds)  # pairs of arguments
        assert(length(inds) % 2 == 0)
        inds = collect(zip(inds[1:2:end], inds[2:2:end]))
    end

    [assert(isa(x, Pair) || isa(x, Symbol)) for x in inds]
    inds = [isa(x, Pair) ? x : Pair(x, Colon()) for x in inds]
    ordered    = @p filter inds not*issqueezer | map fst
    squeezed   = @p filter inds issqueezer | map fst
    implicitorder = @p filter a.names not*inside squeezed | filter not*inside ordered
    ordered = @p concat implicitorder ordered

    d = Dict(inds...)
    inds = [get(d, x, Colon())  for x in a.names]
    newnames = Any[]
    for i in 1:length(a.names)
        isa(inds[i], Integer) ? nothing : push!(newnames, a.names[i])
    end

    b = Base.slice(a.data, inds...)
    if ordered == newnames
        return named(b, newnames...)
    else
        perm = [findfirst(x .== newnames) for x in ordered]
        return named(permutedims(b, perm), newnames[perm]...)
    end
end

end # module

