module TestDisplayDescription

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_display_description()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Description Display" begin
        
        # ====================================================================
        # UNIT TESTS - Display Function
        # ====================================================================
        
        @testset "Basic display" begin
            io = IOBuffer()
            descriptions = ((:a, :b), (:b, :c))
            show(io, MIME"text/plain"(), descriptions)
            output = String(take!(io))
            expected = "(:a, :b)\n(:b, :c)"
            @test output == expected
            
            # Three descriptions
            io = IOBuffer()
            descriptions2 = ((:a,), (:b,), (:c,))
            show(io, MIME"text/plain"(), descriptions2)
            output2 = String(take!(io))
            @test output2 == "(:a,)\n(:b,)\n(:c,)"
        end
        
        @testset "Edge cases - empty and single" begin
            # Empty catalog
            io = IOBuffer()
            show(io, MIME"text/plain"(), ())
            @test String(take!(io)) == ""
            
            # Single description
            io = IOBuffer()
            show(io, MIME"text/plain"(), ((:a, :b),))
            @test String(take!(io)) == "(:a, :b)"
            
            # Single description with one symbol
            io = IOBuffer()
            show(io, MIME"text/plain"(), ((:x,),))
            @test String(take!(io)) == "(:x,)"
        end
        
        @testset "Large catalogs" begin
            # 10 descriptions
            descriptions = (
                (:a, :b), (:c, :d), (:e, :f), (:g, :h), (:i, :j),
                (:k, :l), (:m, :n), (:o, :p), (:q, :r), (:s, :t)
            )
            io = IOBuffer()
            show(io, MIME"text/plain"(), descriptions)
            output = String(take!(io))
            lines = split(output, '\n')
            @test length(lines) == 10
            @test lines[1] == "(:a, :b)"
            @test lines[10] == "(:s, :t)"
            
            # 15 descriptions
            descriptions2 = (
                (:a, :b), (:c, :d), (:e, :f), (:g, :h), (:i, :j),
                (:k, :l), (:m, :n), (:o, :p), (:q, :r), (:s, :t),
                (:u, :v), (:w, :x), (:y, :z), (:aa, :bb), (:cc, :dd)
            )
            io = IOBuffer()
            show(io, MIME"text/plain"(), descriptions2)
            output2 = String(take!(io))
            lines2 = split(output2, '\n')
            @test length(lines2) == 15
        end
        
        @testset "Complex descriptions" begin
            # Descriptions with many symbols (5+ each)
            descriptions = (
                (:a, :b, :c, :d, :e),
                (:f, :g, :h, :i, :j),
                (:k, :l, :m, :n, :o, :p)
            )
            io = IOBuffer()
            show(io, MIME"text/plain"(), descriptions)
            output = String(take!(io))
            lines = split(output, '\n')
            @test length(lines) == 3
            @test lines[1] == "(:a, :b, :c, :d, :e)"
            @test lines[2] == "(:f, :g, :h, :i, :j)"
            @test lines[3] == "(:k, :l, :m, :n, :o, :p)"
            
            # Mixed sizes
            descriptions2 = (
                (:a,),
                (:b, :c),
                (:d, :e, :f),
                (:g, :h, :i, :j),
                (:k, :l, :m, :n, :o)
            )
            io = IOBuffer()
            show(io, MIME"text/plain"(), descriptions2)
            output2 = String(take!(io))
            lines2 = split(output2, '\n')
            @test length(lines2) == 5
        end
        
        @testset "Output format consistency" begin
            # Verify no trailing newline on last item
            descriptions = ((:a, :b), (:c, :d))
            io = IOBuffer()
            show(io, MIME"text/plain"(), descriptions)
            output = String(take!(io))
            @test !endswith(output, '\n')
            
            # Verify newlines between items
            @test occursin("\n", output)
            @test count(c -> c == '\n', output) == 1  # Exactly one newline for 2 items
            
            # Three items should have 2 newlines
            descriptions2 = ((:a,), (:b,), (:c,))
            io = IOBuffer()
            show(io, MIME"text/plain"(), descriptions2)
            output2 = String(take!(io))
            @test count(c -> c == '\n', output2) == 2
        end
        
        @testset "Special symbol names" begin
            # Long symbol names
            descriptions = ((:very_long_symbol_name, :another_long_name),)
            io = IOBuffer()
            show(io, MIME"text/plain"(), descriptions)
            output = String(take!(io))
            @test occursin("very_long_symbol_name", output)
            @test occursin("another_long_name", output)
            
            # Symbols with numbers
            descriptions2 = ((:x1, :x2, :x3),)
            io = IOBuffer()
            show(io, MIME"text/plain"(), descriptions2)
            output2 = String(take!(io))
            @test output2 == "(:x1, :x2, :x3)"
        end
    end
end

end # module

test_display_description() = TestDisplayDescription.test_display_description()
