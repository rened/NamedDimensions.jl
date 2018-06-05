println("\n\n\nStarting runtests.jl $(join(ARGS, " ")) ...")
pushfirst!(LOAD_PATH, joinpath(dirname(@__FILE__), "../src"))


using Test, NamedDimensions, FunctionalData, StatsBase

@testset "basic" begin
    data = [1 2 3;4 5 6]
    n = named(data, :a, :b)
    r = named(n, :a => 2)
    @test r.data == [4,5,6]
    @test r.names == [:b]
    @test array(r) == [4,5,6]

    @test ndims(n) == 2
    @test size(n) == (2,3)
    @test size(n,1) == 2
    @test size(n,:a) == 2
    @test size(n,2) == 3
    @test size(n,:b) == 3
    @test length(n) == 6
    @test len(n) == 3

    r = @p named n :a
    @test r.names == [:b, :a]
    @test size(r.data) == (3,2)

    n = named(data, :c)
    @test n.names == [:dimA, :c]

    b = ones(2,3,4)
    n = named(b, :a, :b, :c)
    r = @p named n :a :b
    @test r.names == [:c, :a, :b]
    @test size(r.data) == (4,2,3)

    r = @p named n :a :b | named :c :a
    @test r.names == [:b, :c, :a]
    @test size(r.data) == (3,4,2)

    r = @p named data :a :b | named (:b=>2:3)
    @test r.names == [:a, :b]
    @test r.data == [2 3; 5 6]
    r = @p named data :a :b | named (:a=>1:2)
    @test r.names == [:b, :a]
    @test r.data == data'

    n = named(data, :a, :b)
    @test n[:a] == at(n,:a)
    @test (@p n :b (2:3)) == named(n, :b => 2:3)
    @test (@p n :b (2:3) :a 2) == named([5,6], :b)

    @testset "linear indexing" begin
        @test n[1] == 1
        @test n[2:3] == [4,2]
    end

    buf = IOBuffer()
    showinfo(buf,n)
    @test String(take!(buf)) == "----  2 a x 3 b\n    type: Array{Int64,2}   size: (2, 3)\n    min:  1   max: 6\n    mean: 3.5   median: 3.5\n"
    showinfo(buf, n, "n in runtests")
    @test String(take!(buf)) == "n in runtests  --  2 a x 3 b\n    type: Array{Int64,2}   size: (2, 3)\n    min:  1   max: 6\n    mean: 3.5   median: 3.5\n"

    @test minimum(n) == 1
    # @test maximum(n) == 6
    # @test mean(n) == 3.5
    # @test minimum(n,1) == named([1,2,3],:b)
    # @test minimum(n,:a) == named([1,2,3],:b)
    # @test minimum(n,2) == named([1,4],:a)
    # @test minimum(n,:b) == named([1,4],:a)
    # @test maximum(n,2) == named([3,6],:a)
    # @test std(n,2) == named(vec(std(n.data,2)), :a)
    # @test std(n,:a) == named(vec(std(n.data,1)), :b)
    # @test n .+ n == named([2 4 6;8 10 12], :a, :b)
    # @test n .+ [1 2 3] == named([2 4 6; 5 7 9], :a, :b)
    # @test array(named(ones(2,3,4)) .+ ones(2)) == 2*ones(2,3,4)
    # @test array(named(ones(2,3,4)) .+ ones(2,1)) == 2*ones(2,3,4)
    # @test array(named(ones(2,3,4)) .+ ones(2,1,1)) == 2*ones(2,3,4)
    # @test n .+ [1 2]' == named([2 3 4; 6 7 8], :a, :b)
    # @test [1 2 3] .+ n == named([2 4 6; 5 7 9], :a, :b)
    # @test [1 2]' .+ n == named([2 3 4; 6 7 8], :a, :b)
    # @test n .* data == named(data.^2, :a, :b)
    # @test n * data' == named([14 32; 32 77], :a, :dimB)
    # @test (@p minimum n :b | minimum :a) == 1

    # @test NamedDimensions.dimnames(named(rand(2,3),:a,:b), 1) == [:dimA]
    # @test NamedDimensions.dimnames(named(rand(2,3),:dimA,:b), 1) == [:dimB]
    # @test NamedDimensions.dimnames(named(rand(2,3),:dimA,:dimB), 1) == [:dimC]
    # @test NamedDimensions.dimnames(named(rand(2,3),:dimC,:dimB), 1) == [:dimA]
    # @test NamedDimensions.dimnames(named(rand(2,3),:dimC,:dimB), 3) == [:dimA, :dimD, :dimE]
end

@testset "FunctionalData" begin
    data = [1 2 3;4 5 6]
    n = named(data, :a, :b)

    @test concat(n,n) == named(concat(data,data), :a, :b)
    @test flatten([n,n]) == named(concat(data,data), :a, :b)
    @test concat(n,n) == named(concat(data,data), :a, :b)
    @test flatten([n,n]) == named(concat(data,data), :a, :b)
    @test stack([n,n], :c) == named(stack(Any[data,data]), :a, :b, :c)
    @test unstack(stack([n,n], :c)) == [named(data, :a, :b), named(data, :a, :b)]

    @test fst(n) == named([1,4], :a)
    @test last(n) == named([3,6], :a)
    @test last(n,:b) == named([3,6], :a)
    @test last(n,:a) == named([4,5,6], :b)
    @test take(n,2) == named([1 2; 4 5], :a, :b)
    @test takelast(n,2) == named([2 3; 5 6], :a, :b)
    @test part(n,3:3) == named(col([3;6]), :a, :b)
    @test drop(n,2) == part(n, 3:3)

    @test named(n,:a=>:end) == named([4,5,6],:b)
    @test named(n,:b=>:end) == named([3,6], :a)

    # @test (@p map n id) == n
    # @test (@p map n array) == n.data

    # @test (@p map2 n n plus) == named(data+data, :a, :b)
    # @test (@p map2 n data plus) == named(data+data, :a, :b)
    # @test (@p map2 data n plus) == named(data+data, :a, :b)
end

println("done!")    













