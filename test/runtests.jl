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

function test2()
    println("---------------------")
    a = rand(10)
    tempvec2 = Temporalarray(a; num=4, haslabel=false)
    t, i = get_temp(tempvec2)
    t .= ones(10)
    display(tempvec2)
    println("---------------------")

    a = rand(10)
    tempvec2 = Temporalarray(a; num=4, haslabel=true)
    t, i = new_temp_withlabel(tempvec2, "cat")
    t .= ones(10) * 100
    display(tempvec2)
    println("---------------------")

    t2, i2 = new_temp_withlabel(tempvec2, "dog")
    t2 .= zeros(10)
    display(tempvec2)
    println("---------------------")

    unused!(tempvec2, i2)
    t3, i3 = new_temp_withlabel(tempvec2, "bird")
    t3 .= ones(10)
    display(tempvec2)


    t4, i4 = load_temp_withlabel(tempvec2, "bird")
    display(t4)

    t4, i4 = load_temp_withlabel(tempvec2, "cat")
    display(t4)



    println("---------------------")
    a = rand(10)
    tempvec2 = Temporalarray(a; labeltype=Symbol, num=4, haslabel=true)
    t, i = new_temp_withlabel(tempvec2, :cat)
    t .= ones(10) * 120
    display(tempvec2)

    t4, i4 = load_temp_withlabel(tempvec2, :cat)
    display(t4)
    println("---------------------")
end


@testset "TemporalArrays.jl" begin
    # Write your tests here.
    test()

    test2()
end
