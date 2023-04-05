function test_exceptions()

e = AmbiguousDescription((:e,))
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = InconsistentArgument("e")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = IncorrectMethod(:e)
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = IncorrectArgument("blabla")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = IncorrectOutput("blabla")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = NotImplemented("blabla")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

end