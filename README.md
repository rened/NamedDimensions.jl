# NamedDimensions

[![Build Status](https://travis-ci.org/rened/NamedDimensions.jl.png)](https://travis-ci.org/rened/NamedDimensions.jl)
[![Build Status](http://pkg.julialang.org/badges/NamedDimensions_0.4.svg)](http://pkg.julialang.org/?pkg=NamedDimensions&ver=0.4)
[![Build Status](http://pkg.julialang.org/badges/NamedDimensions_0.5.svg)](http://pkg.julialang.org/?pkg=NamedDimensions&ver=0.5)

This package allows to assign names to the dimensions of a multidimensional array and to index, slice and permute using these names. Also, mathematical operators like `*` and `.+` are fully supported, as well as statistical functions like `mean` and `std`.

It can be used standalone, but also provides tight integration with [FunctionalData.jl](https://github.com/rened/FunctionalData.jl).

### Functions

```jl
N = NamedDims(data, indices...)    # construct new NamedDims from array or NamedDims
N = named(data, indices...)

# valid indices: :a, :b => 1, :c => 1:2

M = named(N, indices...)           # index into NamedDim N
M = N[indices...]                  # these notations are equivalent
M = N(indices...)

a = array(N)                       # obtain unterlying data
a = array(N, indices...)           # same as array(named(...))

names(a)                           # names of the dimensions
ndims(a)                           # number of dimensions
size(a)                            # size of underlying array
size(a, i::Int)                    # size along dimension i
size(a, s::Symbol)                 # size along dimention s
length(a)                          # number of elements
len(a)                             # equal to size(ndims(N))
```


### Examples

#### Construction

```jl
data = [1 2 3; 4 5 6]

# from array
N = named(data, :a, :b)

# from another NamedDims
named(N, :b => 2:3)            # == named([2 3; 5 6], :a, :b)

# providing fewer names than dimensions
named(data, :b)                # == named(data, :dimA, :b)

# access underlying data
array(N)                       # == data

```

#### Indexing / Slicing
```jl
data = [1 2 3; 4 5 6]
N = named(data, :a, :b)

N[:a => 2]              # == named([4,5,6], :b)
N[:a => 2, :b = 2:3]    # == named([5 6], :a, :b)
N[:a, 2, :b, 2:3]       # == named([5 6], :a, :b)
N[:a, :b]               # == data

# alternative syntax
named(N, :a => 2)            
named(N, :a => 2, :b = 2:3)  
named(N, :a, 2, :b, 2:3)     
named(N, :a, :b)             

# alternative syntax 2
N(:a => 2)            
N(:a => 2, :b = 2:3)  
N(:a, 2, :b, 2:3)     
N(:a, :b)             

# combined indexing and returning of underlying array
array(N, :b => 2:3)            # == [2 3; 5 6]
```

#### Permuting

```jl
data = [1 2 3; 4 5 6]
N = named(data, :a, :b)

# data is permuted so that order of last dimension 
# matches specified indices
N[:b, :a]                      # == named(data', :b, :a)
N[:a]                          # == named(data', :b, :a)
N[:b]                          # == N

N[:a => 2, :b => 2:3]          # == named([5 6], :a, :b)
N[:b => 2:3, :a => 2]          # == named([5 6]', :b, :a)

# leading dimensions are automatically carried over
N = named(ones(2,3,4), :a, :b, :c)
N[:c, :a]                      # == N[:b, :c, :a]
                               # == named(ones(3,4,2), :b, :c, :a)
```

#### Computing

```jl
data = [1 2 3; 4 5 6]
N = named(data, :a, :b)

N .+ ones(2,1)                 # == named(data+ones(2,1), :a, :b)
N * ones(3,1)                  # == named(sum(data,2), :a, :dimA)
N * N'                         # == named(data*data', :a, :a)

minimum(N,:a)                  # == named([1,2,3], :b)
std(N,:b)                      # == named(vec(std(N.data,2)), :a)

```
