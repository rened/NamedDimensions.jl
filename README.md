# NamedDimensions

[![Build Status](https://travis-ci.org/rened/NamedDimensions.jl.svg?branch=master)](https://travis-ci.org/rened/NamedDimensions.jl)

This package allows to assign names to the dimensions of a multidimensional array and to index, slice and permute using these names.

### Functions

```jl
NamedDims(data, indices...)    # index/construct new NamedDims from array or NamedDims
named(data, indices...)

array(data)                    # obtain unterlying data
array(data, indices...)        # same as array(named(...))

names(a::NamedDims)            # return the dimensions' names
```



### Examples

```jl
data = [1 2 3; 4 5 6]

# constructing
N = named(data, :a, :b)
named(N, :b => 2:3)            # == named([2 3; 5 6], :a, :b)
array(N, :b => 2:3)            # == [2 3; 5 6]
named(data, :b)                # == named(data, :dim1, :b)

# indexing
array(N, :a => 2)              # == [4 5 6]
array(N, :a => 2, :b = 2:3)    # == [5 6]
array(N, :a, 2, :b, 2:3)       # == [5 6]
array(N, :a, :b)               # == data

# permuting
array(N, :b, :a)               # == data'
array(N, :b)                   # == data

N = named(ones(2,3,4), :a, :b, :c)
array(N, :c, :a)               # of size 3 x 4 x 2
```
