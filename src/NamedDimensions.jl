VERSION >= v"0.4.0-dev+6521" && __precompile__()

module NamedDimensions
using FunctionalData

export NamedDims, named, array, names, at
immutable NamedDims{N}
    data
    names::Array{Symbol}
    function NamedDims(a, names...)
        names = collect(names)
        assert(length(names) <= ndims(a))
        len(unique(names)) != len(names) && error("NamedDimensions: Duplicate names: $names")

        if length(names) < ndims(a)
            names = vcat(dimnames(names, ndims(a)-length(names)), names)
        end
        new(a, names)
    end
end

named(a::AbstractArray, names::Array{Symbol}) = named(a, names...)
named(a::AbstractArray, names...) = (assert(all(x->isa(x,Symbol), names)); NamedDims{ndims(a)}(a, names...))

array(a::NamedDims) = a.data
array(a::NamedDims, inds...) = array(named(a, inds...))
import Base.getindex
getindex(a::NamedDims, inds...) = named(a, inds...)
import FunctionalData.at
at(a::NamedDims, inds...) = named(a, inds...)
call(a::NamedDims, inds...) = named(a, inds...)

names(a::NamedDims) = a.names

import Base.==
==(a::NamedDims, b::NamedDims) = a.names == b.names && a.data == b.data

import Base.size
size(a::NamedDims) = size(a.data)
size(a::NamedDims, dim::Int) = size(a.data, dim)
size(a::NamedDims, dim::Symbol) = size(a.data, getind(a, dim))
import Base.length
length(a::NamedDims) = length(a.data)
import FunctionalData.len
len(a::NamedDims) = len(a.data)

function getind(a::NamedDims, x::Symbol)
    ind = findfirst(x.==a.names)
    if ind == 0
        error("NamedDimensions: No dimension $x in $(a.names)")
    end
    ind
end

function named(a::NamedDims, inds...)
    isname(x) = (isa(x, Pair) && isa(x.first, Symbol)) || isa(x, Symbol)
    issqueezer(x) = isa(x, Pair) && isa(x.second, Integer)
    if all(x->!isa(x, Pair), inds) && any(x->!isa(x, Symbol), inds)  # pairs of arguments
        assert(length(inds) % 2 == 0)
        inds = @p map2 inds[1:2:end] inds[2:2:end] Pair
        return named(a, inds...)
    end

    [assert(isa(x, Pair) || isa(x, Symbol)) for x in inds]
    inds = [isa(x, Pair) ? x : Pair(x, Colon()) for x in inds]
    ordered    = @p filter inds not*issqueezer | map fst
    squeezed   = @p filter inds issqueezer | map fst
    invalid = @p concat ordered squeezed | filter not*inside a.names
    if !isempty(invalid)
        error("NamedDimensions: Invalid dimensions $invalid . Valid dimensions are $(a.names)")
    end
    implicitorder = @p filter a.names not*inside squeezed | filter not*inside ordered
    ordered = @p concat implicitorder ordered

    d = Dict(inds...)
    inds = [get(d, x, Colon())  for x in a.names]
    newnames = Symbol[]
    for i in 1:length(a.names)
        isa(inds[i], Integer) ? nothing : push!(newnames, a.names[i])
    end

    b = Base.slice(a.data, inds...)
    if ordered == newnames
        return named(b, newnames)
    else
        perm = [findfirst(x .== newnames) for x in ordered]
        return named(permutedims(b, perm), newnames[perm])
    end
end

import FunctionalData.showinfo
function showinfo(io::IO, a::NamedDims, comment::String = "")
    print(io, comment, "  --   ")
    @p map2 a.names size(a.data) ((n,s) -> "$s$n") | join " x " | println io _
    showinfo(io, a.data; showheader = false)
end

for f in [:mean, :maximum, :minimum, :median, :std, :var]
    @eval import Base.$f
    @eval $f(a::NamedDims, dim::Int) = named(squeeze($f(a.data,dim),dim), dropat(a.names,dim)...)
    @eval $f(a::NamedDims, dim::Symbol) = (assert(dim in a.names); $f(a, getind(a, dim)))
end

for f in [:.+, :.-, :.*, :./, :.\, :.^]
    @eval import Base.$f
    @eval $f(a::NamedDims, b::AbstractArray) = ndims(a.data) >= ndims(b) ? named($f(a.data, b), a.names) : f(a.data, b)
    @eval $f(a::AbstractArray, b::NamedDims) = ndims(b.data) >= ndims(a) ? named($f(a, b.data), b.names) : f(a, b.data)
    @eval function $f(a::NamedDims, b::NamedDims)
        named($f(a.data, b.data), length(a.names) > length(b.names) ? a.names : b.names)
    end
end

for f in [:-, :+]
    @eval import Base.$f
    @eval $f(a::NamedDims, b::AbstractArray) = named($f(a.data, b), a.names)
    @eval $f(a::AbstractArray, b::NamedDims) = named($f(a, b.data), b.names)
    @eval function $f(a::NamedDims, b::NamedDims)
        assert(a.names == b.names)
        named($f(a.data, b.data), a.names)
   end
end

chars = collect('A':'Z')
dimnames(a::NamedDims, args...) = dimnames(a.names, args...)
function dimnames(names, n = 2)
    @p filter [Symbol("dim$(chars[i])") for i in 1:n+len(names)] not*inside names | take n
end

for (f,inds) in [(:*,[1,4]), (:/, [1,3]), (:\, [2,4])]
    @eval import Base.$f
    @eval $f(a::NamedDims, b::AbstractArray) = named($f(a.data, b), concat(a.names, dimnames(a))[$inds])
    @eval $f(a::AbstractArray, b::NamedDims) = named($f(a, b.data), concat(dimnames(a), b.names)[$inds])
    @eval function $f(a::NamedDims, b::NamedDims)
        named($f(a.data, b.data), concat(a.names, b.names)[$inds])
   end
end


end # module







