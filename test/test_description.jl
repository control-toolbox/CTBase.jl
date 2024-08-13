function test_description()

#
descriptions = ()
descriptions = add(descriptions, (:a,))
descriptions = add(descriptions, (:b,))
@test descriptions[1] == (:a,)
@test descriptions[2] == (:b,)

# get the complete description of the chosen method
algorithmes = ()
algorithmes = add(algorithmes, (:descent, :bfgs, :bissection))
algorithmes = add(algorithmes, (:descent, :bfgs, :backtracking))
algorithmes = add(algorithmes, (:descent, :bfgs, :fixedstep))
algorithmes = add(algorithmes, (:descent, :gradient, :bissection))
algorithmes = add(algorithmes, (:descent, :gradient, :backtracking))
algorithmes = add(algorithmes, (:descent, :gradient, :fixedstep))

@test getFullDescription((:descent,), algorithmes) == (:descent, :bfgs, :bissection)
@test getFullDescription((:bfgs,), algorithmes) == (:descent, :bfgs, :bissection)
@test getFullDescription((:bissection,), algorithmes) == (:descent, :bfgs, :bissection)
@test getFullDescription((:backtracking,), algorithmes) == (:descent, :bfgs, :backtracking)
@test getFullDescription((:fixedstep,), algorithmes) == (:descent, :bfgs, :fixedstep)
@test getFullDescription((:fixedstep, :gradient), algorithmes) == (:descent, :gradient, :fixedstep)

# incorrect description
@test_throws AmbiguousDescription getFullDescription((:ttt,), algorithmes)
@test_throws AmbiguousDescription getFullDescription((:descent, :ttt), algorithmes)

# diff
x=(:a,:b,:c)
y=(:b,)
@test remove(x, y) == (:a, :c)
@test typeof(remove(x, y)) <: Description

# inclusion and different sizes
algorithmes = ()
algorithmes = add(algorithmes, (:a, :b, :c)) 
algorithmes = add(algorithmes, (:a, :b, :c, :d))
@test getFullDescription((:a, :b), algorithmes) == (:a, :b, :c)
@test getFullDescription((:a, :b, :c, :d), algorithmes) == (:a, :b, :c, :d)

# inclusion and different sizes - switch ordering 
# priority to the first with max shared elements
algorithmes = ()
algorithmes = add(algorithmes, (:a, :b, :c, :d))
algorithmes = add(algorithmes, (:a, :b, :c)) 
@test getFullDescription((:a, :b), algorithmes) == (:a, :b, :c, :d)
@test getFullDescription((:a, :b, :c, :d), algorithmes) == (:a, :b, :c, :d)

# add a description already in the list
algorithmes = ()
algorithmes = add(algorithmes, (:a, :b, :c))
@test_throws IncorrectArgument add(algorithmes, (:a, :b, :c))


end