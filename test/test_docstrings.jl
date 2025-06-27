function test_docstrings()

    @testset "code_unchanged_check" begin
        original_code = """
        function add(x, y)
            return x + y
        end
        """
        
        # Test où le code n'a pas changé
        pairs = [
            ("add", "function add(x, y)\n    return x + y\nend")
        ]
        res = CTBaseDocstring.code_unchanged_check(pairs, original_code; display=false)
        @test res == 0


        # Test où le code a changé
        pairs_modif = [
            ("add", "function add(x, y)\n    return x - y\nend")
        ]
        res_modif = CTBaseDocstring.code_unchanged_check(pairs_modif, original_code; display=false)
        @test res_modif == 1

    end
    @testset "extract_docstring_code_pairs" begin
        
        ai_text = """
\"\"\"
Adds two numbers.
\"\"\"
function add(x, y)
    return x + y
end

\"\"\"
Subtracts two numbers.
\"\"\"
function subtract(x, y)
    return x - y
end
"""

    expected_pairs = [
        ("Adds two numbers.", "function add(x, y)\n    return x + y\nend"),
        ("Subtracts two numbers.", "function subtract(x, y)\n    return x - y\nend")
    ]
        
        pairs, _ = CTBaseDocstring.extract_docstring_code_pairs(ai_text)
        
        @test pairs == expected_pairs
        
    end

end

