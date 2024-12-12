function test_exception()
    e = CTBase.AmbiguousDescription((:e,))
    @test_throws ErrorException error(e)
    @test typeof(sprint(showerror, e)) == String

    e = CTBase.IncorrectArgument("e")
    @test_throws ErrorException error(e)
    @test typeof(sprint(showerror, e)) == String

    e = CTBase.IncorrectMethod(:e)
    @test_throws ErrorException error(e)
    @test typeof(sprint(showerror, e)) == String

    e = CTBase.IncorrectOutput("blabla")
    @test_throws ErrorException error(e)
    @test typeof(sprint(showerror, e)) == String

    e = CTBase.NotImplemented("blabla")
    @test_throws ErrorException error(e)
    @test typeof(sprint(showerror, e)) == String

    e = CTBase.ExtensionError(:tata)
    @test_throws ErrorException error(e)
    @test typeof(sprint(showerror, e)) == String
end
