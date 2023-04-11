using MLStyle

function bench(file::String)

    file_name = split(file, ".")[1]
    print("Benching $file_name.jl")

    file_name_output = joinpath("bench", file_name * ".md")
    open(file_name_output, write=true, append=false) do f
        write(f, "# Benchmarks for $file_name.jl\n\n")
        write(f, "```julia\n")
    end

    has_displayed = false

    function mapexpr(expr)

        #dump(expr)
        Base.remove_linenums!(expr)

        open(file_name_output, write=true, append=true) do f

            if has_displayed 
                write(f, "```julia\n")
                has_displayed = false
            end
            
            #  dump(expr)
            @match expr begin
                :( display(be) ) => begin
                    has_displayed = true
                    write(f, "```\n\n")
                    write(f, "```bash\n")
                    show(f, "text/plain", be)
                    write(f, "\n```\n\n")
                    expr = :()
                end
                _ => begin
                    write(f, string(expr) * "\n\n")
                end
            end

        end

        return expr 

    end

    include(mapexpr, file)

end
