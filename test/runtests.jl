using TemporalArrays
using Test

function test()
    a = rand(10)
    tempvec = Temporalarray(a)
    display(tempvec)
    b = tempvec[1]
    println(b)
    display(tempvec)
    c = tempvec[2]
    println(c)
    display(tempvec)

    tempvec2 = Temporalarray(a; num=4)
    d1 = tempvec2[1]
    println(d1)
    display(tempvec2)
    println("---------------------")
    d2 = tempvec2[2]
    println(d2)
    display(tempvec2)
    unused!(tempvec2, 2)
    println("---------------------")
    d3 = tempvec2[3]
    println(d3)
    display(tempvec2)
    println("---------------------")
    d6 = tempvec2[6]
    println(d6)
    display(tempvec2)
    println("---------------------")
    #vecd = tempvec2[3:10]
end


@testset "TemporalArrays.jl" begin
    # Write your tests here.
    test()
end
