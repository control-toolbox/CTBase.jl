module TestExceptionConfig

using Test
using CTBase
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
Tests for exception configuration (config.jl)
"""
function test_exception_config()
    @testset "Exception Configuration" verbose = VERBOSE showtiming = SHOWTIMING begin
        
        @testset "Stacktrace Control - Default Value" begin
            # Test default value is true (full stacktrace display)
            @test CTBase.get_show_full_stacktrace() == true
        end
        
        @testset "Stacktrace Control - Set to True" begin
            # Test setting to true (full Julia stacktraces)
            CTBase.set_show_full_stacktrace!(true)
            @test CTBase.get_show_full_stacktrace() == true
        end
        
        @testset "Stacktrace Control - Set to False" begin
            # Test setting back to false
            CTBase.set_show_full_stacktrace!(false)
            @test CTBase.get_show_full_stacktrace() == false
        end
        
        @testset "Stacktrace Control - Multiple Toggles" begin
            # Test multiple toggles work correctly
            original = CTBase.get_show_full_stacktrace()
            
            CTBase.set_show_full_stacktrace!(true)
            @test CTBase.get_show_full_stacktrace() == true
            
            CTBase.set_show_full_stacktrace!(false)
            @test CTBase.get_show_full_stacktrace() == false
            
            CTBase.set_show_full_stacktrace!(true)
            @test CTBase.get_show_full_stacktrace() == true
            
            # Restore original state
            CTBase.set_show_full_stacktrace!(original)
        end
        
        @testset "Stacktrace Control - Return Value" begin
            # Test that set_show_full_stacktrace! returns nothing
            result = CTBase.set_show_full_stacktrace!(false)
            @test isnothing(result)
        end
    end
end

end # module

test_config() = TestExceptionConfig.test_exception_config()
