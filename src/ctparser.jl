#
# problem definition as a 'julia like' syntax


import Base.show      # for overloading show()

using MLStyle         # for parsing
using Printf          #

export @def
export print_parsed_code
export set_verbose_level
export CtParserException
export print_generated_code

# only export then debugging
export get_parsed_line
export code_debug_info

#
# _code "class"
# -------------------------

# Parser exception (to normalize error output)
mutable struct CtParserException <: Exception
    msg::String
    CtParserException(msg::String) = new("@def parsing error: " * msg )
end

# type of input lines
@enum _type e_time e_state_scalar e_state_vector e_control_scalar e_control_vector e_constraint e_alias e_objective_min e_objective_max e_variable

# store a parsed line
mutable struct _code
    line::Union{Expr, Symbol}         # line of code (initial, but also transformed after unaliasing)

    # result of first parsing phase
    type::_type                       # type of this code
    content::Array{Any}               # user dependant (can be Symbol, Expr, Float, etc...)

    # for constraints
    name::Union{Symbol, Nothing}      # constraint name

    # user/debug information (code_debug_info)
    initial_line::Union{Expr, Symbol} # initial line of code
    info::String                      # debug info
    code::String                      # final code after tranformation

    # struct constructors
    _code(l, t, c)    = new(l, t, c, nothing, l, "", "")
    function _code(l, t, c, n)
        # named constraint is tricky
        if n isa Integer
            n = "eq" * string(n)
            new(c[1], t, c, Symbol(n), l, "", "")
        elseif n isa Expr
            n = "eq" * string(n)
            new(c[1], t, c, Symbol(n), l, "", "")
        else
            new(c[1], t, c, n, l, "", "")
        end
    end
end

#
# methods for _code
#

# overload show()
function Base.show(io::IO, c::_code)
    if isnothing(c.name)
        println(io, "Code: line=$(c.initial_line), type=$(c.type), content=$(c.content), info=$(c.info)")
    else
        println(io, "Code: line=$(c.initial_line), type=$(c.type), content=$(c.content), name=$(c.name), info=$(c.info)")
    end
end

#
# parser part
# -------------------------

#
# internal global variables
#
_parsed_code::Array{_code} = []  # memorize all code lines during parsing
_verbose_level = 0           # default = do not print at all
_syntax_only   = false       # parser only checks the syntax (no code generation)
_generated_code::Array{String} = [] # memorize generated code

#
# remove all LineNumberNode on expression (these lines will break the pattern matching)
#
remove_line_number_node = @λ begin
    e :: Expr           ->
            let tl = map(remove_line_number_node, e.args)
                Expr(e.head, filter(!isnothing, tl)...)
            end
    :: LineNumberNode -> nothing
    a                   -> a
end

#
# define a CT problem
# -------------------
macro def( args... )

    # problem to parse is the last argument of this macro
    # other args are for the macro itself
    # for the moment:
    # - syntax_only (boolean, default = false) -> stop just after parsing
    # useful globals
    global _syntax_only

    # parse macros args
    _syntax_only = false

    for i in args[begin:end-1]
        @when :( syntax_only = true ) = i begin
            _syntax_only = true
        end
    end

    # extract the problem from args
    prob = args[end]

    # start from scratch (may be modified later)
    global _parsed_code = []
    global _generated_code = []

    # pass 1:
    #
    # - parse
    # - detect dupplicates
    # - store everything in _parsed_code
    #
    count = 0 # (starts with 0 because, it will be increased **before** use)

    # sanity test (prob.args exists)

    for i ∈ 1:length(prob.args)
        # recursively remove all line nodes (which break in case
        # of imbricated expressions)
        node = prob.args[i] |> remove_line_number_node

        verbose(100, "= node = ", node)
        if isa(node, LineNumberNode) || isnothing(node)
            continue
        end

        count += 1
        # time instruction
        #
        @when :($t ∈ [ $a, $b ], time) = node begin
            if _types_already_parsed(e_time)
                return :(throw(CtParserException("multiple time instructions")))
            end
            push!(_parsed_code, _code( node, e_time, [ t, a, b ]))
            _parsed_code[count].info = "(temporary_1: time instruction)"
            continue
        end

        # state instructions
        #
        @when :($s ∈ R^$d, state ) = node begin
            if _types_already_parsed(e_state_scalar, e_state_vector)
                return :(throw(CtParserException("multiple state instructions")))
            end
            push!(_parsed_code, _code( node, e_state_vector, [s, d]))
            _parsed_code[count].info = "(temporary_1: state vector)"
            continue
        end
        @when :($s ∈ R, state ) = node begin
            if _types_already_parsed(e_state_scalar, e_state_vector)
                return :(throw(CtParserException("multiple state instructions")))
            end
            push!(_parsed_code, _code( node, e_state_scalar, [s]))
            _parsed_code[count].info = "(temporary_1: state scalar)"
            continue
        end
        @when :($s[$d], state ) = node begin
            if _types_already_parsed(e_state_scalar, e_state_vector)
                return :(throw(CtParserException("multiple state instructions")))
            end
            push!(_parsed_code, _code( node, e_state_vector, [s, d]))
            _parsed_code[count].info = "(temporary_1: state vector)"
            continue
        end
        @when :($s, state ) = node begin
            if _types_already_parsed(e_state_scalar, e_state_vector)
                return :(throw(CtParserException("multiple state instructions")))
            end
            push!(_parsed_code, _code( node, e_state_scalar, [s]))
            _parsed_code[count].info = "(temporary_1: state scalar)"
            continue
        end

        # control instructions
        #
        @when :($s ∈ R^$d, control ) = node begin
            if _types_already_parsed(e_control_scalar, e_control_vector)
                return :(throw(CtParserException("multiple control instructions")))
            end
            push!(_parsed_code, _code( node, e_control_vector, [s, d]))
            _parsed_code[count].info = "(temporary_1: control vector)"
            continue
        end
        @when :($s ∈ R, control ) = node begin
            if _types_already_parsed(e_control_scalar, e_control_vector)
                return :(throw(CtParserException("multiple control instructions")))
            end
            push!(_parsed_code, _code( node, e_control_scalar, [s]))
            _parsed_code[count].info = "(temporary_1: contraol scalar)"
            continue
        end
        @when :($s[$d], control ) = node begin
            if _types_already_parsed(e_control_scalar, e_control_vector)
                return :(throw(CtParserException("multiple control instructions")))
            end
            push!(_parsed_code, _code( node, e_control_vector, [s, d]))
            _parsed_code[count].info = "(temporary_1: control vector)"
            continue
        end
        @when :($s, control ) = node begin
            if _types_already_parsed(e_control_scalar, e_control_vector)
                return :(throw(CtParserException("multiple control instructions")))
            end
            push!(_parsed_code, _code( node, e_control_scalar, [s]))
            _parsed_code[count].info = "(temporary_1: control scalar)"
            continue
        end

        # variables (two syntaxes allowed)
        #
        @when :($t ∈ R, variable ) = node begin
            if _type_and_var_already_parsed( e_variable, [t])[1]
                return :(throw(CtParserException("variable defined twice")))
            end
            push!(_parsed_code,_code( node, e_variable, [t]))
            _parsed_code[count].info = "(temporary_1: scalar variable)"
            continue
        end
        @when :($t, variable ) = node begin
            if _type_and_var_already_parsed( e_variable, [t])[1]
                return :(throw(CtParserException("variable defined twice")))
            end
            push!(_parsed_code,_code( node, e_variable, [t]))
            _parsed_code[count].info = "(temporary_1: scalar variable)"
            continue
        end

        # aliases
        #
        @when :($a = $b) = node begin
            if _type_and_var_already_parsed( e_alias, [a, b])[1]
                return :(throw(CtParserException("alias defined twice")))
            end
            push!(_parsed_code,_code( node, e_alias, [a, b]))
            _parsed_code[count].info = "(temporary_1: alias)"
            continue
        end

        # objectives
        #
        @when :($a -> begin min end) = node begin
            if _types_already_parsed(e_objective_max, e_objective_min)
                return :(throw(CtParserException("objective defined twice")))
            end
            push!(_parsed_code,_code( node, e_objective_min, [a]))
            _parsed_code[count].info = "(temporary_1: min objective)"
            continue
        end
        @when :($a → begin min end) = node begin
            if _types_already_parsed(e_objective_max, e_objective_min)
                return :(throw(CtParserException("objective defined twice")))
            end
            push!(_parsed_code,_code( node, e_objective_min, [a]))
            _parsed_code[count].info = "(temporary_1: min objective)"
            continue
        end
        @when :($a -> min ) = node begin
            if _types_already_parsed(e_objective_max, e_objective_min)
                return :(throw(CtParserException("objective defined twice")))
            end
            push!(_parsed_code,_code( node, e_objective_min, [a]))
            _parsed_code[count].info = "(temporary_1: min objective)"
            continue
        end
        @when :($a → min) = node begin
            if _types_already_parsed(e_objective_max, e_objective_min)
                return :(throw(CtParserException("objective defined twice")))
            end
            push!(_parsed_code,_code( node, e_objective_min, [a]))
            _parsed_code[count].info = "(temporary_1: min objective)"
            continue
        end
        #
        @when :($a -> begin max end) = node begin
            if _types_already_parsed(e_objective_max, e_objective_min)
                return :(throw(CtParserException("objective defined twice")))
            end
            push!(_parsed_code,_code( node, e_objective_max, [a]))
            _parsed_code[count].info = "(temporary_1: max objective)"
            continue
        end
        @when :($a → begin max end) = node begin
            if _types_already_parsed(e_objective_max, e_objective_min)
                return :(throw(CtParserException("objective defined twice")))
            end
            push!(_parsed_code,_code( node, e_objective_max, [a]))
            _parsed_code[count].info = "(temporary_1: max objective)"
            continue
        end
        @when :($a -> max) = node begin
            if _types_already_parsed(e_objective_max, e_objective_min)
                return :(throw(CtParserException("objective defined twice")))
            end
            push!(_parsed_code,_code( node, e_objective_max, [a]))
            _parsed_code[count].info = "(temporary_1: max objective)"
            continue
        end
        @when :($a → max) = node begin
            if _types_already_parsed(e_objective_max, e_objective_min)
                return :(throw(CtParserException("objective defined twice")))
            end
            push!(_parsed_code,_code( node, e_objective_max, [a]))
            _parsed_code[count].info = "(temporary_1: max objective)"
            continue
        end

        # anything else is a constraint (and must be `julia parseable`)
        #
        @when :($e => ($n)) = node begin
            if _type_and_var_already_parsed( e_constraint, [e])[1]
                return :(throw(CtParserException("constraint defined twice")))
            end
            push!(_parsed_code,_code( node, e_constraint, [e], n))
            _parsed_code[count].info = "(temporary_1: named constraint)"
            continue
        end

        @when :($e , ($n)) = node begin
            if _type_and_var_already_parsed( e_constraint, [e])[1]
                return :(throw(CtParserException("constraint defined twice")))
            end
            push!(_parsed_code,_code( node, e_constraint, [e], n))
            _parsed_code[count].info = "(temporary_1: named constraint)"
            continue
        end

        @when :($e) = node begin
            if _type_and_var_already_parsed( e_constraint, [e])[1]
                return :(throw(CtParserException("constraint defined twice")))
            end
            push!(_parsed_code,_code( node, e_constraint, [e]))
            _parsed_code[count].info = "(temporary_1: constraint)"
            continue
        end

        @printf "%40s : %s\n" type node
        return :(throw(CtParserException("unknown instruction")))
    end

    if _syntax_only
        # stop here
        verbose(10, "Problem parsed correctly: ", length(_parsed_code), " instruction(s)")
        return :(true)
    end

    # parsing finished, evaluation can start

    # sanity check
    # need at least:
    # - time
    # - control
    # - state
    # - objective
    # - constraint
    if  !_types_already_parsed(e_time) ||
        !_types_already_parsed(e_control_scalar, e_control_vector) ||
        !_types_already_parsed(e_state_scalar, e_state_vector) ||
        ! (_types_already_parsed(e_objective_min) || _types_already_parsed(e_objective_max)) ||
        !_types_already_parsed(e_constraint)
        #return :(throw(CtParserException("incomplete problem")))
        # incomplete problem is accepted (can be enhance by hand later)
        verbose(20, "Incomplete problem")
    end

    # store the code to produce
    _final_code = []

    # 0/ some global values to record
    _time_variable    = :very_stupid_name_for_a_variable
    _t0_variable      = :very_stupid_name_for_a_variable
    _tf_variable      = :very_stupid_name_for_a_variable
    _state_variable   = :very_stupid_name_for_a_variable
    _control_variable = :very_stupid_name_for_a_variable
    _time_variable    = nothing
    _t0_variable      = nothing
    _tf_variable      = nothing
    _state_variable   = nothing
    _control_variable = nothing

    # 1/ create ocp
    push!(_final_code, :(ocp = Model()))

    # 2/ call time!

    # is time is present in parsed code ?
    (c, index) = _line_of_type(e_time)
    if c != nothing
        _time_variable = c.content[1]
        x = c.content[2]  # aka t0
        y = c.content[3]  # aka tf

        # look for x and y in variable's list
        ( status_0, t_index_0) = _type_and_var_already_parsed( e_variable, [x])
        ( status_f, t_index_f) = _type_and_var_already_parsed( e_variable, [y])

        if status_0 && status_f
            # if t0 and tf are both variables, throw an exception
            # (can be changed in the future)
            return :(throw(CtParserException("cannot release both ends of time interval")))
        end

        # is t0 a variable ?
        if status_0
            _tf_variable = y
            code = quote time!(ocp,:final, $(esc(y))) end
            push!(_final_code, code)
            _parsed_code[index].info = "final time definition with $y"
            _store_code_as_string( "time!(ocp,:final, $y)", index)
            _parsed_code[t_index_0].info = "use $x as initial time variable"
            _parsed_code[t_index_0].code = "<none: included in time!() call>"
            @goto after_time
        end

        # is tf a variable ?
        if status_f
            _t0_variable = x
            code = quote time!(ocp,:initial, $(esc(x))) end
            push!(_final_code, code)
            _parsed_code[index].info = "initial time definition with $x"
            _store_code_as_string( "time!(ocp,:initial, $x)", index)
            _parsed_code[t_index_f].info = "use $y as final time variable"
            _parsed_code[t_index_f].code = "<none: included in time!() call>"
            @goto after_time
        end
        # nor t0 and tf are variables (in Main scope)
        _t0_variable = x
        _tf_variable = y

        code = quote time!(ocp, [ $(esc(x)), $(esc(y))] ) end
        push!(_final_code, code)
        _parsed_code[index].info = "time definition with [ $x, $y]"
        _store_code_as_string( "time!(ocp, [ $x, $y])", index)

        @label after_time
    else
        # no time defintion is present, cannot continue
        return :(throw(CtParserException("a time variable must be provided in order to process other directives")))
    end

    # 3/ call state!
    (c, index) = _line_of_type(e_state_vector)
    if c != nothing
        _state_variable = c.content[1]  # aka state name
        d = c.content[2]  # aka dimention
        code = quote state!(ocp, $(esc(d))) end
        push!(_final_code, code)
        _parsed_code[index].info = "state vector ($_state_variable) of dimension $d"
        _store_code_as_string( "state!(ocp, $d)", index)
    end
    (c, index) = _line_of_type(e_state_scalar)
    if c != nothing
        _state_variable = c.content[1]  # aka state name
        code = quote state!(ocp, 1) end
        push!(_final_code, code)
        _parsed_code[index].info = "state scalar ($_state_variable)"
        _store_code_as_string( "state!(ocp, 1)", index)
    end


    # 4/ call control!
    (c, index) = _line_of_type(e_control_vector)
    if c != nothing
        _control_variable = c.content[1]  # aka control name
        d = c.content[2]  # aka dimention
        code = quote control!(ocp, $(esc(d))) end
        push!(_final_code, code)
        _parsed_code[index].info = "control vector ($_control_variable) of dimension $d"
        _store_code_as_string( "control!(ocp, $d)", index)
    end
    (c, index) = _line_of_type(e_control_scalar)
    if c != nothing
        _control_variable = c.content[1]  # aka control name
        code = quote control!(ocp, 1) end
        push!(_final_code, code)
        _parsed_code[index].info = "control scalar ($_control_variable)"
        _store_code_as_string( "control!(ocp, 1)", index)
    end

    # 5/ explicit aliases
    for c ∈ _parsed_code
        if c.type != e_alias
            continue
        end

        # alias found
        a = c.content[1]  # a = b
        b = c.content[2]
        for l ∈ _parsed_code
            if  ( l.type != e_constraint ) &&
                ( l.type != e_objective_min ) &&
                ( l.type != e_objective_max )
                continue
            end

            if has(l.line, a)
                verbose(50,"ALIAS: replace $a by $b in: ", l.line)
                e = subs(l.line, a, b)
                verbose(50,"AFTER: ", e)
                l.line = e
            end
        end

    end

    # 6/ implicit aliases (from state/control)
    for tt in [ e_state_vector, e_control_vector]

        # find definition of state_vector and control_vector
        (c, index) = _line_of_type(tt)

        if c != nothing
            a = c.content[1]  # aka name
            m = c.content[2]  # aka dimension

            for i ∈ 1:m       # generate a\_i up to dimension

                symb_1 = Symbol(a, Char(8320+i))  # a\_i
                symb_2 = :( $a[$i] )              # a[i]

                for l ∈ _parsed_code
                    if  ( l.type != e_constraint ) &&
                        ( l.type != e_objective_min ) &&
                        ( l.type != e_objective_max )
                        continue
                    end

                    if has(l.line, symb_1)
                        verbose(50,"ALIAS: replace $symb_1 by $symb_2 in: ", l.line)
                        e = subs(l.line, symb_1, symb_2)
                        verbose(50,"AFTER: ", e)
                        l.line = e
                    end
                end
            end
        end
    end

    # 7/ constraints
    @show _time_variable
    @show _t0_variable
    @show _tf_variable
    @show _state_variable
    @show _control_variable

    for i ∈ 1:length(_parsed_code)
        c = _parsed_code[i]

        c.type != e_constraint && continue

        @show c.line

        _code = @match c.line begin
            :( $x == $y )      => x
            :( $x <= $y )      => y
            :( $x ≤  $y )      => y
            :( $x <= $y <= $z) => y
            :( $x ≤  $y  ≤ $z) => y
        end
        @show _code
        ( _t, _e ) =  constraint_type(_code,
                                      _time_variable,
                                      _t0_variable,
                                      _tf_variable,
                                      _state_variable,
                                      _control_variable)

        if isnothing(c.name)
            @show _t
            @show _e
        else
            @show _t
            @show _e
            @show c.name
        end
    end

    # 6/ objective
    (c, index) = _line_of_type(e_objective_min)
    (c, index) = _line_of_type(e_objective_max)

    # x) final line (return the created ocp object)
    push!(_final_code, :(ocp))

    # concatenate all code as a simple block
    e = Expr(:block, _final_code...)

    # and return it
    :( $e )

end # macro @def


#
# (internal) find if some types are already parsed
#
function _types_already_parsed( types::_type...)
    for c in _parsed_code
        for t in types
            if c.type == t
                return true
            end
        end
    end
    return false
end # function _types_already_parsed

#
# (internal) find if some type/var is already parsed
#
function _type_and_var_already_parsed( type::_type, content::Any )
    count = 1
    for c in _parsed_code
        if c.type == type && c.content == content
            return true, count
        end
        count += 1
    end
    return false, 0
end # function _type_and_var_already_parsed

#
# (internal) return the (first) line corresponding to a type
#
function _line_of_type( type::_type)
    count = 1
    for c in _parsed_code
        if c.type == type
            return c, count
        end
        count += 1
    end
    return nothing, 0
end # _line_of_type

#
# (internal) recognize constraints
#

function _classify_constraints()
    for i ∈ 1:length(_parsed_code)
        c = _parsed_code[i]
        if c.type == e_constraint
            if c.content[1].head == Symbol(:comparison)
                _parsed_code[i].info = "(temporary_2: constraint double comparison)"
                continue
            end

            if  c.content[1].head == Symbol(:call) &&
                ( c.content[1].args[1] == Symbol(:≤) ||
                c.content[1].args[1] == Symbol(:<=) ||
                c.content[1].args[1] == Symbol(:<))
                _parsed_code[i].info = "(temporary_2: constraint simple comparison)"
                continue
            end

            if  c.content[1].head == Symbol(:call) &&
                c.content[1].args[1] == Symbol(:(==))
                _parsed_code[i].info = "(temporary_2: constraint egality)"
                continue
            end

        end
    end
end

#
# (internal)
#
function _store_code_as_string(info::String, index::Integer)
    global _parsed_code
    global _generated_code

    _parsed_code[index].code = info
    push!(_generated_code, info)
end

#
# verbose message: only print then level <= verbose_level
#
# level == 0     -> always print
# level increase -> less print (mode debug)
#
function verbose(level::Int, args...)
    global _verbose_level
    if _verbose_level >= level
        for x in args
            print(x)
        end
        if length(args) > 0
            print("\n")
        end
    end
end # function verbose

#
# helpers to modify the parser behavior.
# useful for debugging/testing
# --------------------------------------

#
# as it says: set verbosity
#
# the highest -> more verbose
#
# Remark: level will be limited to interval [0, 100]
function set_verbose_level(level::Int)
    global _verbose_level
    _verbose_level = level < 0 ? 0 : ( level > 100 ? 100 : level )
end

#
# print parsed informations (debug)
#
function print_parsed_code( )
    for c in _parsed_code
        show(c)
    end
end # function print_parsed_code

#
# getter of a line of code (debug)
#
function get_parsed_line( i::Integer )
    if i <= 0 || i > size(_parsed_code)[1]
        return false
    end
    return _parsed_code[i]
end

#
# print informations on each parsed lines
#
function code_debug_info( )
    if size(_parsed_code)[1] == 0
        println("=== No debug information from CtParser (empty code)")
        return
    end
    println("=== Debug information from CtParser:")
    count = 1
    for c in _parsed_code
        println("Line number: $count") ; count += 1
        println("- initial line: ", c.initial_line |> remove_line_number_node)
        if c.line != c.initial_line
            println("- current line: ", c.line |> remove_line_number_node)
        end
        println("- content     : ", c.content |> remove_line_number_node)
        println("- info        : ", c.info)
        println("- code        : ", c.code)
        println("")
    end
end # parsed_code_debug_info

#
# print generated code as strings
#
function print_generated_code()
    if size(_generated_code)[1] == 0
        println("=== No code for this definition")
        return
    end
    println("=== Generated code")
    println("ocp = Model()")
    println.(_generated_code)
    return
end # print_generated_code
