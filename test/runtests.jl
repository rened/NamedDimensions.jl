using NamedDimensions
using FactCheck, FunctionalData

data = [1 2 3;4 5 6]
a = named(data, :a, :b)
r = named(a, :a => 2)
@fact r.data --> [4 5 6]
@fact r.names --> [:b]
@fact array(r) --> [4 5 6]

r = @p named a :a
@fact r.names --> [:b, :a]
@fact size(r.data) --> (3,2)

n = named(data, :c)
@fact n.names --> [:dim1, :c]

b = ones(2,3,4)
n = named(b, :a, :b, :c)
r = @p array n :a :b
@fact r.names --> [:c, :a, :b]
@fact size(r.data) --> (4,2,3)

r = @p named n :a :b | array :c :a
@fact r.names --> [:b, :c, :a]
@fact size(r.data) --> (3,4,2)

r = @p named data :a :b | named (:b=>2:3)
@fact r.names --> [:a, :b]
@fact r.data --> [2 3; 5 6]
r = @p named data :a :b | named (:a=>1:2)
@fact r.names --> [:a, :b]
@fact r.names --> [2 5; 3 6]

n = named(data, :a, :b)
@fact n[:a] --> at(:a)
@fact (@p n :b (2:3)) --> named(:b => 2:3)
@fact (@p n :b (2:3) :a 2) --> named([5 6], :a, :b)

buf = IOBuffer()
showinfo(buf,n)
@fact takebuf_string(buf) --> "  --   2a x 3b\ntype: Array{Int64,2}   size: (2,3)\n    min:  1   max: 6\n    mean: 3.5   median: 3.5\n"
showinfo(buf, n, "n in runtests")
@fact takebuf_string(buf) --> "  --   2a x 3b\ntype: Array{Int64,2}   size: (2,3)\n    min:  1   max: 6\n    mean: 3.5   median: 3.5\nn in runtests  --   2a x 3b\ntype: Array{Int64,2}   size: (2,3)\n    min:  1   max: 6\n    mean: 3.5   median: 3.5\n"
