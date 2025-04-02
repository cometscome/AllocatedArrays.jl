module TemporalArrays

mutable struct Temporalarray{TG,TL}
    _data::Vector{TG}
    _labels::TL #Nothing or Vector are candidates
    _flagusing::Vector{Bool}
    _indices::Vector{Int64}
    Nmax::Int64
    _reusemode::Bool

    function Temporalarray(a::TG, labels::TL; Nmax=1000, reusemode=false) where {TG,TL}
        num = length(labels)
        _data = Vector{TG}(undef, num)
        _flagusing = zeros(Bool, num)
        _indices = zeros(Int64, num)
        for i = 1:num
            _data[i] = similar(a)
        end
        return new{TG,TL}(_data, labels, _flagusing, _indices, Nmax, reusemode)
    end

    function Temporalarray(a::TG; num=1, Nmax=1000, reusemode=false) where {TG}
        _data = Vector{TG}(undef, num)
        _labels = nothing
        _flagusing = zeros(Bool, num)
        _indices = zeros(Int64, num)
        for i = 1:num
            _data[i] = similar(a)
        end
        return new{TG,Nothing}(_data, _labels, _flagusing, _indices, Nmax, reusemode)
    end

    function Temporalarray(_data::Vector{TG}, _labels::TL, _flagusing, _indices, Nmax, _reusemode) where {TG,TL}
        return new{TG,TL}(_data, _labels, _flagusing, _indices, Nmax, _reusemode)
    end

    function Temporalarray(_data::Vector{TG}, _flagusing, _indices, Nmax, _reusemode) where {TG,TL}
        _labels = nothing
        return new{TG,TL}(_data, _labels, _flagusing, _indices, Nmax, _reusemode)
    end

end

function Temporalarray_fromvector(a::Vector{TG}; Nmax=1000, reusemode=false) where {TG}
    num = length(a)
    _flagusing = zeros(Bool, num)
    _indices = zeros(Int64, num)
    return Temporalarray(a, _flagusing, _indices, Nmax, reusemode)
end
function Temporalarray_fromvector(a::Vector{TG}, labels::TL; Nmax=1000, reusemode=false) where {TG,TL}
    num = length(a)
    _flagusing = zeros(Bool, num)
    _indices = zeros(Int64, num)
    return Temporalarray(a, labels, _flagusing, _indices, Nmax, reusemode)
end
export Temporalarray_fromvector

set_reusemode!(t::Temporalarray, reusemode) = t._reusemode = reusemode
export set_reusemode!

Base.eltype(::Type{Temporalarray{TG}}) where {TG} = TG

Base.length(t::Temporalarray) = length(t._data)

Base.size(t::Temporalarray) = size(t._data)

function Base.firstindex(::Temporalarray)
    return 1
end

function Base.lastindex(t::Temporalarray)
    return length(t._data)
end

function Base.getindex(t::Temporalarray{TG}, i::Int) where {TG}
    #display(t)
    if i > length(t._data)
        @warn "The length of the Temporalarray is shorter than the index $i. New temporal fields are created."
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

function Base.getindex(t::Temporalarray{TG}, I::Vararg{Int,N}) where {TG,N}
    data = TG[]
    for i in I
        push!(data, t[i])
    end
    return data
end

function Base.getindex(t::Temporalarray{TG}, I::AbstractVector{T}) where {TG,T<:Integer}
    data = TG[]
    for i in I
        push!(data, t[i])
    end
    return data
end

function Base.display(t::Temporalarray{TG}) where {TG}
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

function get_temp(t::Temporalarray{TG}) where {TG}
    n = length(t._data)
    i = findfirst(x -> x == 0, t._indices)
    if i == nothing
        @warn "All $n temporal fields are used. New one is created. Usually, this means that something is wrong."
        #error("All $n temporal fields are used. New one is created.")
        i = n + 1
    end

    return t[i], i
end

function get_temp(t::Temporalarray{TG}, num) where {TG}
    n = length(t._data)
    i_s = Int64[]
    t_s = TG[]
    for k = 1:num
        tk, i = get_temp(t)
        push!(t_s, tk)
        push!(i_s, i)
    end
    return t_s, i_s
end

function unused!(t::Temporalarray{TG}, i) where {TG}
    if t._indices[i] != 0
        index = t._indices[i]
        t._flagusing[index] = false
        t._indices[i] = 0
    end
end


function unused!(t::Temporalarray{TG}, I::AbstractVector{T}) where {TG,T<:Integer}
    for i in I
        unused!(t, i)
    end
end

function unused!(t::Temporalarray{TG}) where {TG}
    for i = 1:length(t)
        unused!(t, i)
    end
end


export Temporalarray, unused!, get_temp

end
