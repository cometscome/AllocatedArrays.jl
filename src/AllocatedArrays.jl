module PreallocatedArrays

mutable struct PreallocatedArray{TG,TL,haslabel}
    _data::Vector{TG}
    _labels::Vector{TL}
    _flagusing::Vector{Bool}
    _indices::Vector{Int64}
    Nmax::Int64
    _reusemode::Bool
    const _haslabel::Bool


    function PreallocatedArray(a::TG;
        labeltype=String, haslabel=false, num=1, Nmax=1000, reusemode=false) where {TG}
        _data = Vector{TG}(undef, num)
        TL = Union{Nothing,labeltype}
        if haslabel
            _labels = Vector{TL}(undef, num)
            for k = 1:num
                _labels[k] = nothing
            end
        else
            _labels = TL[]
        end

        _flagusing = zeros(Bool, num)
        _indices = zeros(Int64, num)
        for i = 1:num
            _data[i] = similar(a)
        end
        return new{TG,TL,haslabel}(_data, _labels, _flagusing, _indices, Nmax, reusemode, haslabel)
    end



    function PreallocatedArray(_data::Vector{TG}, _labels::Vector{TL}, _flagusing, _indices, Nmax, _reusemode) where {TG,TL}
        _haslabel = true
        return new{TG,TL,_haslabel}(_data, _labels, _flagusing, _indices, Nmax, _reusemode, _haslabel)
    end

    function PreallocatedArray(_data::Vector{TG}, _flagusing, _indices, Nmax, _reusemode) where {TG}

        _haslabel = false
        TL = Union{Nothing,String}
        _labels = TL[]
        return new{TG,TL,_haslabel}(_data, _labels, _flagusing, _indices, Nmax, _reusemode, _haslabel)
    end

    function PreallocatedArray(a::AbstractVector{TG};
        Nmax=1000, reusemode=false) where {TG<:AbstractVector}
        num = length(a)
        _flagusing = ones(Bool, num)
        _indices = collect(1:num)
        return PreallocatedArray(a, _flagusing, _indices, Nmax, reusemode)
    end

    function PreallocatedArray(a::AbstractVector{TG}, labels::AbstractVector{labeltype};
        Nmax=1000, reusemode=false) where {TG<:AbstractVector,labeltype}
        num = length(a)

        TL = Union{Nothing,labeltype}
        _labels = Vector{TL}(undef, num)
        _labels .= labels
        _flagusing = ones(Bool, num)
        _indices = collect(1:num)
        return PreallocatedArray(a, _flagusing, _indices, Nmax, reusemode)
    end

end


set_reusemode!(t::PreallocatedArray, reusemode) = t._reusemode = reusemode
export set_reusemode!

Base.eltype(::Type{PreallocatedArray{TG}}) where {TG} = TG

Base.length(t::PreallocatedArray) = length(t._data)

Base.size(t::PreallocatedArray) = size(t._data)

function Base.firstindex(::PreallocatedArray)
    return 1
end

function Base.lastindex(t::PreallocatedArray)
    return length(t._data)
end

function Base.getindex(t::PreallocatedArray{TG}, i::Int) where {TG}
    #display(t)
    if i > length(t._data)
        @warn "The length of the PreallocatedArray is shorter than the index $i. New temporal fields are created."
        ndiff = i - length(t._data)
        @assert i <= t.Nmax "The number of the tempralfields $i is larger than the maximum number $(Nmax). Change Nmax."
        for n = 1:ndiff
            push!(t._data, similar(t._data[1]))
            push!(t._flagusing, 0)
            push!(t._indices, 0)
        end
    end
    if t._indices[i] == 0
        index = findfirst(x -> x == 0, t._flagusing)
        t._flagusing[index] = true
        t._indices[i] = index
    else
        if !t._reusemode
            error("This index $i is being using. You should pay attention")
        end
    end

    return t._data[t._indices[i]]
end

function Base.getindex(t::PreallocatedArray{TG}, I::Vararg{Int,N}) where {TG,N}
    data = TG[]
    for i in I
        push!(data, t[i])
    end
    return data
end

function Base.getindex(t::PreallocatedArray{TG}, I::AbstractVector{T}) where {TG,T<:Integer}
    data = TG[]
    for i in I
        push!(data, t[i])
    end
    return data
end

function Base.display(t::PreallocatedArray{TG,TF,false}) where {TG,TF}
    n = length(t._data)
    println("The total number of fields: $n")
    numused = sum(t._flagusing)
    println("The total number of fields used: $numused")
    for i = 1:n
        if t._indices[i] != 0
            #println("The adress $i is used as the index $(t._indices[i])")
            println("The address $(t._indices[i]) is used as the index $i")
        end
    end
    println("The flags: $(t._flagusing)")
    println("The indices: $(t._indices)")
end

function Base.display(t::PreallocatedArray{TG,TF,true}) where {TG,TF}
    n = length(t._data)
    println("The total number of fields: $n")
    numused = sum(t._flagusing)
    println("The total number of fields used: $numused")
    for i = 1:n
        if t._indices[i] != 0
            #println("The adress $i is used as the index $(t._indices[i])")
            println("The address $(t._indices[i]) is used as the index $i label is $(t._labels[i])")
        end
    end
    println("The flags: $(t._flagusing)")
    println("The indices: $(t._indices)")
    println("The labels: $(t._labels)")
end

function get_block(t::PreallocatedArray{TG}) where {TG}
    n = length(t._data)
    i = findfirst(x -> x == 0, t._indices)
    if i == nothing
        @warn "All $n blocks are used. New one is created. Usually, this means that something is wrong."
        i = n + 1
    end

    return t[i], i
end

function new_block_withlabel(t::PreallocatedArray{TG,TL,true}, label::TL) where {TG,TL}
    ti, i = get_block(t)
    #not_undef = [i for i in eachindex(t._labels) if isassigned(t._labels, i)]
    #println(label)
    index = findfirst(x -> x == label, t._labels)
    #println(index)
    @assert index === nothing "this label $label was used! use the other label"

    t._labels[i] = label
    return ti, i
end

function new_block_withlabel(t::PreallocatedArray{TG,TL,false}, label::TL) where {TG,TL}
    error("the PreallocatedArray has no label.")
end
export new_block_withlabel

function load_block_withlabel(t::PreallocatedArray{TG,TL,true}, label::TL) where {TG,TL}
    #not_undef = [i for i in eachindex(t._labels) if isassigned(t._labels, i)]
    index = findfirst(x -> x == label, t._labels)
    @assert index !== nothing "this label $(label) was not set! Something is wrong"
    ti = t._data[index]
    return ti, index
end
export load_block_withlabel

function load_block_withlabel(t::PreallocatedArray{TG,TL,false}, label::TL) where {TG,TL}
    error("the PreallocatedArray has no label.")
end


function get_block(t::PreallocatedArray{TG}, num) where {TG}
    n = length(t._data)
    i_s = Int64[]
    t_s = TG[]
    for k = 1:num
        tk, i = get_block(t)
        push!(t_s, tk)
        push!(i_s, i)
    end
    return t_s, i_s
end

function unused!(t::PreallocatedArray{TG}, i) where {TG}
    if t._indices[i] != 0
        index = t._indices[i]
        t._flagusing[index] = false
        t._indices[i] = 0
    end
end


function unused!(t::PreallocatedArray{TG}, I::AbstractVector{T}) where {TG,T<:Integer}
    for i in I
        unused!(t, i)
    end
end

function unused!(t::PreallocatedArray{TG}) where {TG}
    for i = 1:length(t)
        unused!(t, i)
    end
end


export PreallocatedArray, unused!, get_block

end
