using BenchmarkTools

function tt()
    function bench_scalar(y)
        x = 0
        for i in 1:y
            x += 1.0
        end
        return x
    end

    function bench_scalar_2()
        x = 0
        for i in 1:z
            x += 1.0
        end
        return x
    end

    function bench_scalar_3(z)
        x = 0
        for i in 1:z
            x += w
        end
        return x
    end

    w = 1.0
    z = 1000
    display(@benchmark bench_scalar(z))
    display(@benchmark bench_scalar_2())
    display(@benchmark bench_scalar_3(z))

    function bench_scalar_4()
        x = 0
        for i in 1:zz
            x += 1.0
        end
        return x
    end

    function bench_scalar_5(z)
        x = 0
        for i in 1:z
            x += ww
        end
        return x
    end

    ww = 1.0
    zz = 1000
    display(@benchmark bench_scalar_4())
    display(@benchmark bench_scalar_5(zz))

    function bench_scalar_6(z=z)
        x = 0
        for i in 1:z
            x += 1.0
        end
        return x
    end

    @benchmark bench_scalar_6()
end
