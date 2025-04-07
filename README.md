
# PreallocatedArrays.jl

[![Build Status](https://github.com/cometscome/PreallocatedArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cometscome/PreallocatedArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)


**PreallocatedArrays.jl** is a Julia package that provides a convenient way to manage and reuse allocated blocks of array data. It is particularly useful when you need to allocate many arrays of the same shape or size, and want to reduce overhead by reusing existing allocations.



## Installation

```julia
] add PreallocatedArrays
```

## Main Features

-	**PreallocatedArray** type to store preallocated blocks.

-	**On-demand expansion** of the number of blocks if you request an index larger than the current capacity (up to a user-defined Nmax).

-	**Optional label system** to identify and retrieve blocks by label.

-	Functions to handle usage flags, track which blocks are currently “in use,” and mark them as unused.

## Usage

Below are some basic usage examples. For a more extensive reference, refer to the [tests](https://github.com/cometscome/PreallocatedArrays.jl/blob/main/test/runtests.jl).

### Basic Allocation & Retrieval

```julia
using PreallocatedArrays

# Create a 3×3 random matrix
a = rand(3, 3)

# Create an PreallocatedArray with 4 preallocated blocks of the same size
blockvec = PreallocatedArray(a; num=4, haslabel=false)

# Request one block from the pool
data_block, index = get_block(blockvec)

# Use the block
data_block .= 1.0  # fill with ones

# Mark the block as unused when you're done
unused!(blockvec, index)
```

### Labels

```julia
using PreallocatedArrays

# Create a 10-element random vector
a = rand(10)

# Create an PreallocatedArray with 4 labeled blocks
blockvec2 = PreallocatedArray(a; num=4, haslabel=true)

# Request a block by label
block, idx = new_block_withlabel(blockvec2, "cat")
block .= 100.0

# Later, you can retrieve that same block by its label
same_block, same_idx = load_block_withlabel(blockvec2, "cat")
@assert block === same_block  # They are the same array reference
```

## Creating from Vectors of Arrays

```julia
using PreallocatedArrays

# Suppose you have a vector of 10 Float64 vectors
data = [rand(4) for i in 1:10]

# Create an PreallocatedArray from an existing vector of arrays
blockvec = PreallocatedArray(data)

# Also supports labeling
labels = ["$(i)-th" for i in 1:10]
blockvec_labeled = PreallocatedArray(data, labels)

# Display usage information
display(blockvec_labeled)
```

## Custum type
You can use a custum type. 
For example, if you want to treat the gaugefields in Gaugefields.jl, 
```julia
using Gaugefields
U =  Initialize_Gaugefields(3,0,4,4,4,4)
U1,it = get_block(a)
```

## Important Functions

### 1. ```PreallocatedArray```

Constructor function to create an ```PreallocatedArray``` with optional arguments for:
-	```num::Int``` – initial number of preallocated blocks
-	```haslabel::Bool``` – whether to enable label storage
-	```labeltype``` – the type of labels to store (by default ```String```, can be ```Symbol```, etc.)
-	```Nmax::Int``` – maximum capacity for the allocated array
-	```reusemode::Bool``` – if true, allows reusing a block without raising an error.


### 2. ```get_block(preallocated_array)```

Fetches one unused block and returns ```(block, index)```. If there are no unused blocks, it expands the array up to Nmax.

### 3. ```get_block(preallocated_array, num::Int)```

Fetches num unused blocks and returns ```(blocks, indices)```, where blocks is a vector of blocks, and indices is a vector of the corresponding indices.

### 4. ```new_block_withlabel(preallocated_array, label)```

Fetches one unused block and *assigns* the label provided. Returns ```(block, index)```. If the label already exists, it raises an error.

### 5. ```load_block_withlabel(preallocated_array, label)```

Returns the block previously assigned to ```label```. Raises an error if the label was not set.

### 6. ```unused!(preallocated_array, index)```

Marks a block at a given index as no longer in use. There are also methods to mark multiple indices or *all* blocks as unused.


### 7. ```set_reusemode!(preallocated_array, reusemode)```

Enables or disables reusing a block. If ```reusemode``` is disabled, trying to get a block at an index already in use triggers an error.

