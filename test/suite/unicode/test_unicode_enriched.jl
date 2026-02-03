module TestUnicodeEnriched

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_unicode_enriched()

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Enriched Unicode Errors" begin
        
        # ====================================================================
        # ERROR TESTS - Unicode Functions Exception Quality
        # ====================================================================
        
        @testset "ctindice enriched errors" begin
            # Test negative value
            @test_throws CTBase.IncorrectArgument CTBase.ctindice(-1)
            
            try
                CTBase.ctindice(-1)
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.IncorrectArgument
                @test e.got == "-1"
                @test e.expected == "0-9"
                @test occursin("subscript must be between 0 and 9", e.msg)
                @test occursin("ctindices()", e.suggestion)
                @test e.context == "Unicode subscript generation"
            end
            
            # Test value too large
            @test_throws CTBase.IncorrectArgument CTBase.ctindice(15)
            
            try
                CTBase.ctindice(15)
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.IncorrectArgument
                @test e.got == "15"
                @test e.expected == "0-9"
                @test occursin("ctindices()", e.suggestion)
                @test e.context == "Unicode subscript generation"
            end
        end

        @testset "ctindices enriched errors" begin
            # Test negative value
            @test_throws CTBase.IncorrectArgument CTBase.ctindices(-5)
            
            try
                CTBase.ctindices(-5)
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.IncorrectArgument
                @test e.got == "-5"
                @test e.expected == "≥ 0"
                @test occursin("subscript must be positive", e.msg)
                @test e.context == "Unicode subscript string generation"
            end
        end

        @testset "ctupperscript enriched errors" begin
            # Test negative value
            @test_throws CTBase.IncorrectArgument CTBase.ctupperscript(-1)
            
            try
                CTBase.ctupperscript(-1)
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.IncorrectArgument
                @test e.got == "-1"
                @test e.expected == "0-9"
                @test occursin("superscript must be between 0 and 9", e.msg)
                @test occursin("ctupperscripts()", e.suggestion)
                @test e.context == "Unicode superscript generation"
            end
            
            # Test value too large
            @test_throws CTBase.IncorrectArgument CTBase.ctupperscript(12)
            
            try
                CTBase.ctupperscript(12)
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.IncorrectArgument
                @test e.got == "12"
                @test e.expected == "0-9"
                @test occursin("ctupperscripts()", e.suggestion)
                @test e.context == "Unicode superscript generation"
            end
        end

        @testset "ctupperscripts enriched errors" begin
            # Test negative value
            @test_throws CTBase.IncorrectArgument CTBase.ctupperscripts(-3)
            
            try
                CTBase.ctupperscripts(-3)
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.IncorrectArgument
                @test e.got == "-3"
                @test e.expected == "≥ 0"
                @test occursin("superscript must be positive", e.msg)
                @test e.context == "Unicode superscript string generation"
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Successful Operations
        # ====================================================================
        
        @testset "Successful Unicode operations" begin
            # Test ctindice
            @test CTBase.ctindice(0) == '\u2080'
            @test CTBase.ctindice(5) == '\u2085'
            @test CTBase.ctindice(9) == '\u2089'
            
            # Test ctindices
            @test CTBase.ctindices(0) == "\u2080"
            @test CTBase.ctindices(123) == "\u2081\u2082\u2083"
            
            # Test ctupperscript
            @test CTBase.ctupperscript(0) == '\u2070'
            @test CTBase.ctupperscript(1) == '\u00B9'
            @test CTBase.ctupperscript(2) == '\u00B2'
            @test CTBase.ctupperscript(3) == '\u00B3'
            @test CTBase.ctupperscript(5) == '\u2075'
            
            # Test ctupperscripts
            @test CTBase.ctupperscripts(0) == "\u2070"
            @test CTBase.ctupperscripts(123) == "\u00B9\u00B2\u00B3"
        end
    end

    return nothing
end

end # module

# Export to outer scope for TestRunner
test_unicode_enriched() = TestUnicodeEnriched.test_unicode_enriched()
