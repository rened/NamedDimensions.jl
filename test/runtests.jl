using NamedDimensions
using FactCheck, FunctionalData

facts("All") do
    data = [1 2 3;4 5 6]
    n = named(data, :a, :b)
    r = named(n, :a => 2)
    @fact r.data --> [4,5,6]
    @fact r.names --> [:b]
    @fact array(r) --> [4,5,6]

    @fact ndims(n) --> 2
    @fact size(n) --> (2,3)
    @fact size(n,1) --> 2
    @fact size(n,:a) --> 2
    @fact size(n,2) --> 3
    @fact size(n,:b) --> 3
    @fact length(n) --> 6
    @fact len(n) --> 3

    r = @p named n :a
    @fact r.names --> [:b, :a]
    @fact size(r.data) --> (3,2)

    n = named(data, :c)
    @fact n.names --> [:dimA, :c]

    b = ones(2,3,4)
    n = named(b, :a, :b, :c)
    r = @p named n :a :b
    @fact r.names --> [:c, :a, :b]
    @fact size(r.data) --> (4,2,3)

    r = @p named n :a :b | named :c :a
    @fact r.names --> [:b, :c, :a]
    @fact size(r.data) --> (3,4,2)

    r = @p named data :a :b | named (:b=>2:3)
    @fact r.names --> [:a, :b]
    @fact r.data --> [2 3; 5 6]
    r = @p named data :a :b | named (:a=>1:2)
    @fact r.names --> [:b, :a]
    @fact r.data --> data'

    n = named(data, :a, :b)
    @fact n[:a] --> at(n,:a)
    @fact (@p n :b (2:3)) --> named(n, :b => 2:3)
    @fact (@p n :b (2:3) :a 2) --> named([5,6], :b)

    buf = IOBuffer()
    showinfo(buf,n)
    @fact takebuf_string(buf) --> "  --   2a x 3b\ntype: Array{Int64,2}   size: (2,3)\n    min:  1   max: 6\n    mean: 3.5   median: 3.5\n"
    showinfo(buf, n, "n in runtests")
    @fact takebuf_string(buf) --> "n in runtests  --   2a x 3b\ntype: Array{Int64,2}   size: (2,3)\n    min:  1   max: 6\n    mean: 3.5   median: 3.5\n"

    @fact minimum(n) --> 1
    @fact maximum(n) --> 6
    @fact mean(n) --> 3.5
    @fact minimum(n,1) --> named([1,2,3],:b)
    @fact minimum(n,:a) --> named([1,2,3],:b)
    @fact minimum(n,2) --> named([1,4],:a)
    @fact minimum(n,:b) --> named([1,4],:a)
    @fact maximum(n,2) --> named([3,6],:a)
    @fact std(n,2) --> named(vec(std(n.data,2)), :a)
    @fact std(n,:a) --> named(vec(std(n.data,1)), :b)
    @fact n .+ n --> named([2 4 6;8 10 12], :a, :b)
    @fact n .+ [1 2 3] --> named([2 4 6; 5 7 9], :a, :b)
    @fact n .+ [1 2]' --> named([2 3 4; 6 7 8], :a, :b)
    @fact [1 2 3] .+ n --> named([2 4 6; 5 7 9], :a, :b)
    @fact [1 2]' .+ n --> named([2 3 4; 6 7 8], :a, :b)
    @fact n .* data --> named(data.^2, :a, :b)
    @fact n * data' --> named([14 32; 32 77], :a, :dimB)

    @fact NamedDimensions.dimnames(named(rand(2,3),:a,:b), 1) --> [:dimA]
    @fact NamedDimensions.dimnames(named(rand(2,3),:dimA,:b), 1) --> [:dimB]
    @fact NamedDimensions.dimnames(named(rand(2,3),:dimA,:dimB), 1) --> [:dimC]
    @fact NamedDimensions.dimnames(named(rand(2,3),:dimC,:dimB), 1) --> [:dimA]
    @fact NamedDimensions.dimnames(named(rand(2,3),:dimC,:dimB), 3) --> [:dimA, :dimD, :dimE]
end
