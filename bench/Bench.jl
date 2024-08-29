using MLStyle
using MacroTools

function doBenchMarking(expr, f)
    expr = MacroTools.striplines(expr)
    println("Benchmarking $expr")
    write(f, string(expr) * "\n")
    write(f, "```\n\n")
    write(f, "```bash\n")
    show(f, "text/plain", eval(quote
        $expr
    end))
    write(f, "\n```\n\n")
end

function bench(file::String)
    file_name = split(file, ".")[1]
    println("Benching $file_name.jl\n")

    file_name_output = joinpath("bench", file_name * ".md")
    open(file_name_output, write = true, append = false) do f
        write(f, "# Benchmarks for $file_name.jl\n\n")
        write(f, "```julia\n")
    end

    has_displayed = false

    function mapexpr(expr)

        #println("Nouvelle expr           : ", expr)
        #Base.remove_linenums!(expr)
        #println("Suppression line number : ", expr)
        expr = MacroTools.striplines(expr)
        #println("MacroTools line number  : ", expr, "\n")
        println("Expr  : ", expr)
        #dump(expr)

        open(file_name_output, write = true, append = true) do f
            if has_displayed
                write(f, "```julia\n")
                has_displayed = false
            end

            if hasproperty(expr, :head) &&
               expr.head == :macrocall &&
               expr.args[1] == Symbol("@benchmark")
                has_displayed = true
                doBenchMarking(expr, f)
                expr = :()

            else
                MLStyle.@match expr begin
                    :(display($benchname)) => begin
                        has_displayed = true
                        doBenchMarking(quote
                            $benchname
                        end, f)
                        expr = :()
                    end
                    _ => begin
                        write(f, string(expr) * "\n")
                    end
                end
            end
        end

        return expr
    end

    include(mapexpr, file)
end
