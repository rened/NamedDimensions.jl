__precompile__()

module NamedDimensions
using FunctionalData

export NamedDims, named, array, names, at
immutable NamedDims{T,N}
    data::Array{T,N}
    names::Array{Symbol}
    function NamedDims(a, names...)
        names = collect(names)
        length(names) > ndims(a) && error("NamedDimensions: Got $(length(names)) names $names for $(ndims(a)) dims $(size(a))")
        for i = 1:len(names), j = i+1:len(names)
            names[i]==names[j] && error("NamedDimensions: Duplicate names: $names")
        end

        if length(names) < ndims(a)
            names = vcat(dimnames(names, ndims(a)-length(names)), names)
        end
        new(a, names)
    end
end

named{T}(a::AbstractArray{T,0}, named::Vector{Symbol}) = a[1]
named(a::AbstractArray, names::Vector{Symbol}) = named(a, names...)
named(a::AbstractArray, names...) = (assert(all(x->isa(x,Symbol), names)); NamedDims{eltype(a),ndims(a)}(a, names...))
named(a::NamedDims, names::Vector{Symbol}) = named(a, names...)
named(a, args...) = a

import Base: getindex, eltype, isempty
array(a) = a
array(a::NamedDims) = a.data
array(a::NamedDims, inds...) = array(named(a, inds...))
getindex(a::NamedDims, inds...) = named(a, inds...)
eltype{T,N}(a::NamedDims{T,N}) = T
isempty(a::NamedDims) = len(a) == 0

for f in [:fst, :snd, :third, :last]
    @eval import FunctionalData.$f
    @eval $f(a::NamedDims) = named(squeezer($f(a.data)), droplast(a.names))
    @eval $f(a::NamedDims, x::Symbol) = $f(named(a, x))
end

import FunctionalData.at
at(a::NamedDims, i::Int) = a[last(a.names) => i]

for f in [:take, :takelast, :drop, :droplast, :partition, :partsoflen]
    @eval import FunctionalData.$f
    @eval $f(a::NamedDims, i::Int) = named($f(a.data,i), a.names)
end

for f in [:part, :trimmedpart]
    @eval import FunctionalData.$f
    @eval $f{T}(a::NamedDims, i::DenseArray{T,2}) = named($f(a.data,i), a.names)
    @eval $f(a::NamedDims, i::UnitRange) = named($f(a.data,i), a.names)
    @eval $f(a::NamedDims, i::AbstractVector) = named($f(a.data,i), a.names)
end

import FunctionalData.concat
function concat(a::NamedDims, b::NamedDims)
    assert(a.names == b.names)
    assert(size(fst(a)) == size(fst(b)))
    named(concat(a.data, b.data), a.names)
end

import FunctionalData.flatten
function flatten{T,N}(a::Vector{NamedDims{T,N}})
    assert(all(x->x.names == fst(a).names, a))
    assert(all(x->size(x)[1:end-1] == size(fst(a))[1:end-1], a))
    named(flatten(map(a,array)), fst(a).names)
end

import FunctionalData.stack
function stack(a, name::Symbol)
    assert(all(x->x.names == fst(a).names, a))
    assert(all(x->size(x) == size(fst(a)), a))
    named(stack(map(a,array)), concat(fst(a).names, name))
end

function stack(r, a::NamedDims)
    isempty(r) && return []
    if isa(fst(r), NamedDims)
        return stack(typed(r), last(a.names))
    else
        return stack(r)
    end
end

import FunctionalData: map, map2, map3, map4, map5

function map{T,N}(a::NamedDims{T,N}, f::Function)
    r = [f(at(a,i)) for i in 1:len(a)]
    return stack(r, a)
end
mapper2(f, N, a, b, fa, fb) = stack([f(fa(at(a,i)), fb(at(b,i))) for i in 1:len(N)], N)
squeezer(a::AbstractArray) = size(a,ndims(a)) == 1 ? squeeze(a,ndims(a)) : a
squeezer(a) = a
map2(a::NamedDims, b::NamedDims, f::Function) = mapper2(f,a,a,b,id,id)
map2(a::NamedDims, b, f::Function) = mapper2(f,a,a,b,id,squeezer)
map2(a, b::NamedDims, f::Function) = mapper2(f,b,a,b,squeezer,id)

at(a::NamedDims, inds::Tuple) = at(a.data, inds)
at(a::NamedDims, inds...) = named(a, inds...)
call(a::NamedDims, inds...) = named(a, inds...)

names(a::NamedDims) = a.names

import Base.==
==(a::NamedDims, b::NamedDims) = a.names == b.names && a.data == b.data

import Base.size
size(a::NamedDims) = size(a.data)
size(a::NamedDims, dim::Int) = size(a.data, dim)
size(a::NamedDims, dim::Symbol) = size(a.data, getind(a, dim))
import Base.ndims
ndims(a::NamedDims) = ndims(a.data)
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
    inds = [isa(x, Pair) && x.second == :end ? Pair(x.first, size(a, x.first)) : x for x in inds]
    isname(x) = (isa(x, Pair) && isa(x.first, Symbol)) || isa(x, Symbol)
    issqueezer(x) = isa(x, Pair) && isa(x.second, Integer)
    if length(inds)==1 && !isname(inds[1])
        return a.data[inds...]
    end
    if all(x->!isa(x, Pair), inds) && any(x->!isa(x, Symbol), inds)  # pairs of arguments
        if length(inds) % 2 != 0
            error("NamedDimensions: Expected an even number of parameters, got $(inds)")
        end
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

    b = (VERSION < v"0.5-" ? slice : view)(a.data, inds...)
    if ordered == newnames
        return named(b, newnames)
    else
        perm = [findfirst(x .== newnames) for x in ordered]
        return named(permutedims(b, perm), newnames[perm])
    end
end

import Base.summary
function summary{T,N}(a::NamedDims{T,N})
    @p mapvec2 a.names size(a.data) ((n,s) -> "$s $n") | join " x " | concat " :: NamedDims{$T,$N}"
end

import Base.show
show(io::IO, a::NamedDims) = (println(io, summary(a)); show(io,a.data))

import FunctionalData.showinfo
function showinfo(io::IO, a::NamedDims, comment::AbstractString = "")
    print(io, comment, length(comment) > 0 ? "  --  ": "----  ")
    @p mapvec2 a.names size(a.data) ((n,s) -> "$s $n") | join " x " | println io _
    showinfo(io, a.data; showheader = false)
    a
end

for f in [:sqrt]
    @eval import Base.$f
    @eval $f(a::NamedDims, args...) = named($f(a.data, args...), a.names)
end

for f in [:power, :square]
    @eval import FunctionalData.$f
    @eval $f(a::NamedDims, args...) = named($f(a.data, args...), a.names)
end

for f in [:mean, :maximum, :minimum, :median, :std, :var, :sum]
    @eval import Base.$f
    @eval $f(a::NamedDims) = $f(a.data)
    @eval $f(a::NamedDims, dim::Int) = named(squeeze($f(a.data,dim),dim), dropat(a.names,dim))
    @eval $f(a::NamedDims, dim::Symbol) = $f(a, getind(a, dim))
end

function broadcast(f::Function, smaller::NamedDims, larger::NamedDims)
    assert(all(x->in(x, larger.names), smaller.names))
    last = @p filter larger.names not*inside smaller.names
    orderforsmaller = @p filter larger.names inside smaller.names
    a = isempty(last) ? larger : named(larger, last)
    reorderedsmaller = smaller[orderforsmaller].data
    r = @p f reorderedsmaller a.data
    named(r, concat(orderforsmaller, last))[larger.names] 
end

for f in [:.+, :.-, :.*, :./, :.\, :.^]
    @eval import Base.$f
    @eval $f(a::NamedDims, b::AbstractArray) = ndims(a.data) >= ndims(b)-1 ? named($f(a.data, b), a.names) : $f(a.data, b)
    @eval $f(a::AbstractArray, b::NamedDims) = ndims(b.data) >= ndims(a)-1 ? named($f(a, b.data), b.names) : $f(a, b.data)
    @eval function $f(a::NamedDims, b::NamedDims)
        length(a.names) < length(b.names) ? broadcast($f, a, b) : broadcast($f, b, a)
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
    @eval function $f(a::NamedDims, b::NamedDims)
        named($f(a.data, b.data), concat(a.names, b.names)[$inds])
    end
    @eval $f(a::NamedDims, b::AbstractArray) = named($f(a.data, b), concat(a.names, dimnames(a))[$inds])
    @eval $f(a::AbstractArray, b::NamedDims) = named($f(a, b.data), concat(dimnames(a), b.names)[$inds])
end


end # module







