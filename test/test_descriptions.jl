function test_descriptions()

# make a description from symbols or a tuple of symbols
@test makeDescription(:tt, :vv) == (:tt, :vv)
@test makeDescription((:tt, :vv)) == (:tt, :vv)

#
a = ()
a = add(a, (:tata,))
a = add(a, (:toto,))
@test a[1] == (:tata,)
@test a[2] == (:toto,)

# get the complete description of the chosen method
algorithmes = ()
algorithmes = add(algorithmes, (:descent, :bfgs, :bissection))
algorithmes = add(algorithmes, (:descent, :bfgs, :backtracking))
algorithmes = add(algorithmes, (:descent, :bfgs, :fixedstep))
algorithmes = add(algorithmes, (:descent, :gradient, :bissection))
algorithmes = add(algorithmes, (:descent, :gradient, :backtracking))
algorithmes = add(algorithmes, (:descent, :gradient, :fixedstep))

@test gFD((:descent,), algorithmes) == (:descent, :bfgs, :bissection)
@test gFD((:bfgs,), algorithmes) == (:descent, :bfgs, :bissection)
@test gFD((:bissection,), algorithmes) == (:descent, :bfgs, :bissection)
@test gFD((:backtracking,), algorithmes) == (:descent, :bfgs, :backtracking)
@test gFD((:fixedstep,), algorithmes) == (:descent, :bfgs, :fixedstep)
@test gFD((:fixedstep, :gradient), algorithmes) == (:descent, :gradient, :fixedstep)

# incorrect description
@test_throws AmbiguousDescription gFD((:ttt,), algorithmes)
@test_throws AmbiguousDescription gFD((:descent, :ttt), algorithmes)

# diff
x=(:a,:b,:c)
y=(:b,)
@test x\y == (:a, :c)
@test typeof(x\y) <: Description

# inclusion and different sizes
algorithmes = ()
algorithmes = add(algorithmes, (:a, :b, :c)) 
algorithmes = add(algorithmes, (:a, :b, :c, :d))
@test gFD((:a, :b), algorithmes) == (:a, :b, :c)
@test gFD((:a, :b, :c, :d), algorithmes) == (:a, :b, :c, :d)

# inclusion and different sizes - switch ordering 
# priority to the first with max shared elements
algorithmes = ()
algorithmes = add(algorithmes, (:a, :b, :c, :d))
algorithmes = add(algorithmes, (:a, :b, :c)) 
@test gFD((:a, :b), algorithmes) == (:a, :b, :c, :d)
@test gFD((:a, :b, :c, :d), algorithmes) == (:a, :b, :c, :d)

end