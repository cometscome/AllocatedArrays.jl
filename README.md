
# TemporalArrays.jl

[![Build Status](https://github.com/cometscome/TemporalArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cometscome/TemporalArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)


**TemporalArrays.jl** is a Julia package providing a flexible data structure for allocating, labeling, and reusing array blocks in memory. It is particularly useful in scenarios where you need to frequently allocate and deallocate blocks but want to minimize memory churn.

---

## Features

- **Flexible data storage**: Allocate one or more “temporal fields” (array blocks) from a base array/vector.
- **Optional labeling**: Associate each block with a label (e.g., `String`, `Symbol`) for easier retrieval.
- **Minimal memory churn**: Mark blocks as “unused” and reuse them later.
- **Key API**:
  - `Temporalarray(...)` for constructing a temporal array
  - **`get_temp(t::Temporalarray)`** to find and reserve an *unused* block
  - `new_temp_withlabel` / `load_temp_withlabel` to manage labeled blocks
  - `unused!` to free blocks
  - `set_reusemode!` to allow reusing blocks without explicit freeing

---

## Installation

If the package is registered (for example):

```julia
using Pkg
Pkg.add(url="https://github.com/cometscome/TemporalArrays.jl")
```

## Basic Usage

### Creating a temporal array
```julia
using TemporalArrays

# Create a temporal array from a Vector-like object
data = rand(10)
tempvec = Temporalarray(data)

# Access/allocate the first block
block1 = tempvec[1]
block1 .= 1.0  # Fill it with data
```

### Freeing and Reusing Blocks

```julia
# Mark a used block as unused
unused!(tempvec, 1)

# Acquire a fresh (or reused) block via get_temp
block2, idx2 = get_temp(tempvec)
block2 .= 2.0
```

### Enabling Reuse Mode
```julia
set_reusemode!(tempvec, true)
block3 = tempvec[1]  # Reuse block #1 without calling unused! first
```

## Using Labels

Enable labeling with ```haslabel=true``` to associate each block with a custom label:

```julia
tempvec_labeled = Temporalarray(rand(10); num=4, haslabel=true)

# Acquire a fresh block with a label
tcat, cat_index = new_temp_withlabel(tempvec_labeled, "cat")
tcat .= 100.0

# Retrieve by label
loaded_cat, idx_cat = load_temp_withlabel(tempvec_labeled, "cat")

# Mark as unused when done
unused!(tempvec_labeled, idx_cat)
```

## Important Function: get_temp

```get_temp(t::Temporalarray)``` searches for the first unused block and returns both the block and its index:

```julia
block, idx = get_temp(mytemparray)
```

-	If all blocks are in use, a warning is printed, and it may create a new block if you haven’t reached the Nmax limit.
-	Use this for dynamic allocation whenever you need a new chunk of memory.

You can also get multiple blocks at once:

```julia
blocks, indices = get_temp(mytemparray, 3)
```

## Example from runtest.jl

A simplified example from the test suite:

```julia
using TemporalArrays

# 1) Create
a = rand(10)
tempvec = Temporalarray(a)
block1 = tempvec[1]
println("Block1: ", block1)

# 2) Pre-allocate multiple blocks
tempvec2 = Temporalarray(a; num=4)
blockA = tempvec2[1]
blockB = tempvec2[2]
unused!(tempvec2, 2)

# 3) Using get_temp
blockC, idxC = get_temp(tempvec2)
println("Acquired block index: ", idxC)

# 4) Labeled usage
tempvec_label = Temporalarray(a; num=4, haslabel=true)
tcat, icat = new_temp_withlabel(tempvec_label, "cat")
tcat .= 100
loaded, idx_loaded = load_temp_withlabel(tempvec_label, "cat")
println("Loaded cat block: ", loaded)
unused!(tempvec_label, idx_loaded)
```

## Other Constructors

-	```Temporalarray_fromvector(a::Vector{TG}; Nmax=1000, reusemode=false)```
Create a ```Temporalarray``` from a vector of array-like objects (unlabeled).
-	```Temporalarray_fromvector(a::Vector{TG}, labels::Vector{TL}; Nmax=1000, reusemode=false)```
Create a labeled ```Temporalarray``` from a vector of data blocks and their labels.


