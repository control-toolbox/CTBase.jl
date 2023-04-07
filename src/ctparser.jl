#
# problem definition as a 'julia like' syntax


using MLStyle         # for parsing
using MLStyle.AbstractPatterns: literal
using Printf

export @def
export CtParserException

# only export then debugging
export get_parsed_line
export print_generated_code


#
# _code "class"
# -------------------------

# Parser exception (to normalize error output)
mutable struct CtParserException <: Exception
    msg::String
    CtParserException(msg::String) = new("@def parsing error: " * msg )
end

# type of input lines
#@enum _ctparser_line_type e_time e_state_scalar e_state_vector e_control_scalar e_con#trol_vector e_constraint e_alias e_objective_min e_objective_max e_variable

# store a parsed line
mutable struct _code
    line::Union{Expr, Symbol}               # line of code (initial, but also transformed after unaliasing)

    # result of first parsing phase
    const type::_ctparser_line_type         # type of this code
    const content::Array{Any}               # user dependant (can be Symbol, Expr, Float, etc...)

    # for constraints
    const name::Union{Symbol, Nothing}      # constraint name

    # user/debug information (code_debug_info)
    const initial_line::Union{Expr, Symbol} # initial line of code
    info::String                            # debug info
    code::String                            # final code after tranformation

    # struct constructors
    function _code(_line, _type, _content, _info)
        if _type == e_objective_min ||
            _type == e_objective_max ||
            _type == e_constraint
            new(_content[1], _type, _content, nothing, _line, _info, "")
        else
            new(_line, _type, _content, nothing, _line, _info, "")
        end
    end
    function _code(_line, _type, _content, _info, _name)
        # named constraint is tricky
        if _name isa Integer
            _name = "eq" * string(_name)
            new(_content[1], _type, _content, Symbol(_name), _line, _info, "")
        elseif _name isa Expr
            _name = "eq" * string(_name)
            new(_content[1], _type, _content, Symbol(_name), _line, _info, "")
        else
            new(_content[1], _type, _content, _name, _line, _info, "")
        end
    end
end

#
# methods for _code
#

#
# parser part
# -------------------------

#
# internal global variables
#
# WARNING: these two variables **MUST** be removed from final code
#
_parsed_code::Array{_code} = []  # memorize all code lines during parsing
_generated_code::Array{String} = [] # memorize generated code

#
# remove all LineNumberNode on expression (these lines will break the pattern matching)
#
remove_line_number_node = @λ begin
    e :: Expr           ->
            let tl = map(remove_line_number_node, e.args)
                Expr(e.head, filter(!isnothing, tl)...)
            end
    :: LineNumberNode   -> nothing
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

    # parse macros args
    _syntax_only = false
    _verbose_threshold = 0
    _debug_mode = false

    for i in args[begin:end-1]
        @when :( syntax_only = true ) = i begin
            _syntax_only = true
            continue
        end
        @when :( debug = true ) = i begin
            _debug_mode = true
            continue
        end
        @when :( verbose_threshold = $n ) = i begin
            n = n > 100 ? 100 : n
            n = n <   0 ?   0 : n
            _verbose_threshold = n
            verbose(_verbose_threshold, 1, "== verbose_threshold = ", n)
            continue
        end

        return :(throw(CtParserException("bad option for @def")))
    end

    # extract the problem from args
    prob = args[end]

    # start from scratch (may be modified later)
    global _parsed_code = []
    global _generated_code = []

    #
    # FINAL CODE HERE !
    #
    # _parsed_code = []
    # _generated_code = []

    # pass 1:
    #
    # - parse
    # - detect dupplicates
    # - store everything in _parsed_code
    #

    # sanity test (prob.args exists)
    if ! (prob isa Expr)
        return :(throw(CtParserException("input must be an Expr")))
    end

    for i ∈ 1:length(prob.args)
        # recursively remove all line nodes (which break in case
        # of imbricated expressions)
        node = prob.args[i] |> remove_line_number_node

        verbose(_verbose_threshold, 100, "line = ", node)
        if isa(node, LineNumberNode) || isnothing(node)
            continue
        end

        ( _t, _c ) = input_line_type( node )
        _ts = Symbol(_t)                        # pattern matching on enum cannot be used here
        @match _ts begin
            :e_time => let
                verbose(_verbose_threshold, 50, "E_TIME             with: ", _c)
                if _types_already_parsed( _parsed_code, e_time)
                    return :(throw(CtParserException("multiple time instructions")))
                end
                push!(_parsed_code, _code( node, _t, _c, "(temporary_1: time instruction)"))
            end
            :e_state_scalar=> let
                verbose(_verbose_threshold, 50, "E_STATE_SCALAR     with: ", _c)
                if _types_already_parsed( _parsed_code, e_state_scalar, e_state_vector)
                    return :(throw(CtParserException("multiple state instructions")))
                end
                push!(_parsed_code, _code( node, _t, _c, "(temporary_1: state scalar)"))
            end
            :e_state_vector=> let
                verbose(_verbose_threshold, 50, "E_STATE_VECTOR     with: ", _c)
                if _types_already_parsed( _parsed_code, e_state_scalar, e_state_vector)
                    return :(throw(CtParserException("multiple state instructions")))
                end
                push!(_parsed_code, _code( node, _t, _c, "(temporary_1: state vector)"))
            end
            :e_control_scalar=> let
                verbose(_verbose_threshold, 50, "E_CONTROL_SCALAR   with: ", _c)
                if _types_already_parsed( _parsed_code, e_control_scalar, e_control_vector)
                    return :(throw(CtParserException("multiple control instructions")))
                end
                push!(_parsed_code, _code( node, _t, _c,"(temporary_1: control scalar)"))
            end
            :e_control_vector=> let
                verbose(_verbose_threshold, 50, "E_CONTROL_VECTOR   with: ", _c)
                if _types_already_parsed( _parsed_code, e_control_scalar, e_control_vector)
                    return :(throw(CtParserException("multiple control instructions")))
                end
                push!(_parsed_code, _code( node, _t, _c, "(temporary_1: control vector)"))
            end
            :e_constraint=> let
                verbose(_verbose_threshold, 50, "E_CONSTRAINT       with: ", _c)
                if _type_and_var_already_parsed( _parsed_code,  e_constraint, _c)[1]
                    return :(throw(CtParserException("constraint defined twice")))
                end
                push!(_parsed_code, _code( node, _t, _c, "(temporary_1: constraint)"))
            end
            :e_named_constraint=> let
                verbose(_verbose_threshold, 50, "E_NAMED_CONSTRAINT with: ", _c)
                if _type_and_var_already_parsed( _parsed_code,  e_constraint, [_c[1]])[1]
                    return :(throw(CtParserException("constraint defined twice")))
                end
                push!(_parsed_code, _code( node, e_constraint, [_c[1]], "(temporary_1: named constraint)", _c[2]))
            end
            :e_alias=> let
                verbose(_verbose_threshold, 50, "E_ALIAS            with: ", _c)
                if _type_and_var_already_parsed( _parsed_code,  e_alias, _c)[1]
                    return :(throw(CtParserException("alias defined twice")))
                end
                push!(_parsed_code, _code( node, _t, _c, "(temporary_1: alias)"))
            end
            :e_objective_min=> let
                verbose(_verbose_threshold, 50, "E_OBJECTIVE_MIN    with: ", _c)
                if _types_already_parsed( _parsed_code, e_objective_max, e_objective_min)
                    return :(throw(CtParserException("objective defined twice")))
                end
                push!(_parsed_code, _code( node, _t, _c, "(temporary_1: min objective)"))
            end
            :e_objective_max=> let
                verbose(_verbose_threshold, 50, "E_OBJECTIVE_MAX    with: ", _c)
                if _types_already_parsed( _parsed_code, e_objective_max, e_objective_min)
                    return :(throw(CtParserException("objective defined twice")))
                end
                push!(_parsed_code, _code( node, _t, _c, "(temporary_1: max objective)"))
            end
            :e_variable=> let
                verbose(_verbose_threshold, 50, "E_VARIABLE         with: ", _c)
                if _types_already_parsed(_parsed_code,  e_variable)
                    return :(throw(CtParserException("variable defined twice")))
                end
                push!(_parsed_code, _code( node, _t, _c,  "(temporary_1: scalar variable)"))
            end
            # COV_EXCL_START
            e => let
                # (should never happend, because everything is caught by the previous match)
                return :(throw(CtParserException("cannot parse line")))
            end
            # COV_EXCL_STOP
        end
    end

    if _debug_mode
        _code_debug_info(_parsed_code)
    end

    if _syntax_only
        # stop here
        verbose(_verbose_threshold, 10, "Problem parsed correctly: ", length(_parsed_code), " instruction(s)")
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
    if  !_types_already_parsed( _parsed_code, e_time) ||
        !_types_already_parsed( _parsed_code, e_control_scalar, e_control_vector) ||
        !_types_already_parsed( _parsed_code, e_state_scalar, e_state_vector) ||
        ! (_types_already_parsed( _parsed_code, e_objective_min) || _types_already_parsed( _parsed_code, e_objective_max)) ||
        !_types_already_parsed( _parsed_code, e_constraint)
        #return :(throw(CtParserException("incomplete problem")))
        # incomplete problem is accepted (can be enhance by hand later)
        verbose(_verbose_threshold, 20, "Incomplete problem")
    end

    # store the code to produce
    _final_code = []

    # 0/ some global values to record
    _time_variable    = nothing
    _state_variable   = nothing
    _control_variable = nothing

    _t0_variable      = nothing
    _tf_variable      = nothing

    # 1/ create ocp
    push!(_final_code, :(ocp = Model()))

    # 2/ call time!

    # is time is present in parsed code ?
    (c, index) = _line_of_type( _parsed_code, e_time)
    if c != nothing
        _time_variable = c.content[1]
        x = c.content[2]  # aka t0
        y = c.content[3]  # aka tf

        # look for x and y in variable's list
        ( status_0, t_index_0) = _type_and_var_already_parsed( _parsed_code,  e_variable, [x])
        ( status_f, t_index_f) = _type_and_var_already_parsed( _parsed_code,  e_variable, [y])

        # COV_EXCL_START
        if status_0 && status_f
            # if t0 and tf are both variables, throw an exception
            # this is not possible (06/04/2023) but may be changed in the future
            return :(throw(CtParserException("cannot release both ends of time interval")))
        end
        # COV_EXCL_STOP

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
        # no time definition is present, cannot continue
        return :(throw(CtParserException("a time variable must be provided in order to process other directives")))
    end

    # 3/ call state!
    (c, index) = _line_of_type( _parsed_code, e_state_vector)
    if c != nothing
        _state_variable = c.content[1]  # aka state name
        d = c.content[2]  # aka dimention
        code = quote state!(ocp, $(esc(d))) end
        push!(_final_code, code)
        _parsed_code[index].info = "state vector ($_state_variable) of dimension $d"
        _store_code_as_string( "state!(ocp, $d)", index)
    end
    (c, index) = _line_of_type( _parsed_code, e_state_scalar)
    if c != nothing
        _state_variable = c.content[1]  # aka state name
        code = quote state!(ocp, 1) end
        push!(_final_code, code)
        _parsed_code[index].info = "state scalar ($_state_variable)"
        _store_code_as_string( "state!(ocp, 1)", index)
    end


    # 4/ call control!
    (c, index) = _line_of_type( _parsed_code, e_control_vector)
    if c != nothing
        _control_variable = c.content[1]  # aka control name
        d = c.content[2]  # aka dimention
        code = quote control!(ocp, $(esc(d))) end
        push!(_final_code, code)
        _parsed_code[index].info = "control vector ($_control_variable) of dimension $d"
        _store_code_as_string( "control!(ocp, $d)", index)
    end
    (c, index) = _line_of_type( _parsed_code, e_control_scalar)
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
                verbose(_verbose_threshold, 50,"ALIAS_EXP: replace $a by $b in: ", l.line)
                e = subs(l.line, a, b)
                verbose(_verbose_threshold, 50,"AFTER    : ", e)
                l.line = e
            end
        end

    end

    # 6/ implicit aliases (from state/control)
    # replace subscript indices  by explicit one (eg: x₁ -> x[1])
    for tt in [ e_state_vector, e_control_vector]

        # find definition of state_vector and control_vector
        (c, index) = _line_of_type( _parsed_code, tt)

        if c != nothing
            a = c.content[1]  # aka name
            m = c.content[2]  # aka dimension

            # to be coherent with parsing of Rⁿ
            limit = m isa Symbol ? 9 : m
            for i ∈ 1:limit       # generate a\_i up to dimension

                symb_1 = Symbol(a, Char(8320+i))  # a\_i
                symb_2 = :( $a[$i] )              # a[i]

                for l ∈ _parsed_code
                    if  ( l.type != e_constraint ) &&
                        ( l.type != e_objective_min ) &&
                        ( l.type != e_objective_max )
                        continue
                    end

                    if has(l.line, symb_1)
                        verbose(_verbose_threshold, 50,"ALIAS_IMP: replace $symb_1 by $symb_2 in: ", l.line)
                        e = subs(l.line, symb_1, symb_2)
                        verbose(_verbose_threshold, 50,"AFTER   : ", e)
                        l.line = e
                    end
                end
            end
        end
    end

    # 7/ constraints
    for i ∈ 1:length(_parsed_code)
        c = _parsed_code[i]

        c.type != e_constraint && continue

        name = c.name

        println("")
        @show c.initial_line

        # record the single comparison type for later use
        operator = @match c.line begin
            :( $x == $y )      => :equal
            :( $x ≥  $y )      ||
            :( $x >= $y )      => :gt
            :( $x <= $y )      ||
            :( $x ≤  $y )      => :lt
            :( $x <= $y <= $z) ||
            :( $x ≤  $y  ≤ $z) => :double
            _                  => :other
        end

        @match c.line begin
            :( $x == $y )      ||
            :( $x ≥  $y )      ||
            :( $x >= $y )      ||
            :( $x <= $y )      ||
            :( $x ≤  $y )      => let

                (_t, _c ) = constraint_type(x,
                                            _time_variable,
                                            _t0_variable,
                                            _tf_variable,
                                            _state_variable,
                                            _control_variable)

                @match ( _t, _c ) begin
                    ( :initial, nothing) => let
                        if isnothing(name)
                            println("### initial, $y")
                        else
                            println("### initial, $y, :$name")
                        end
                    end
                    ( :initial, a)  => let
                        if isnothing(name)
                            println("### initial, $_c, $y")
                        else
                            println("### initial, $_c, $y, :$name")
                        end
                    end
                    ( :final  , nothing) => let
                        if isnothing(name)
                            println("### final, $y")
                        else
                            println("### final, $y, :$name")
                        end
                    end
                    ( :final  , a) => let
                        if isnothing(name)
                            println("### final, $_c, $y")
                        else
                            println("### final, $_c, $y, :$name")
                        end
                    end
                    ( :boundary, e) => let
                        if isnothing(name)
                            println("### boundary, ( T0, X0, TF, XF) -> $_c, $y   [not fully implemented]")
                        else
                            println("### boundary, ( T0, X0, TF, XF) -> $_c, $y, :$name   [not fully implemented]")
                        end
                    end
                    ( :control_fun, e) => let
                        if e == _control_variable
                            if isnothing(name)
                                println("### control, $y")
                            else
                                println("### control, $y, :$name")
                            end
                        else
                            if isnothing(name)
                                println("### control, U -> $e, $y  [not fully implemented]")
                            else
                                println("### control, U -> $e, $y, :$name  [not fully implemented]")
                            end
                        end
                    end
                    ( :control_range, e) => let
                        if isnothing(name)
                            println("### control, $e, $x, $z")
                        else
                            println("### control, $e, $x, $z, :$name")
                        end
                    end
                    ( :state_fun, e) => let
                        if e == _state_variable
                            if isnothing(name)
                                println("### state, $y")
                            else
                                println("### state, $y, :$name")
                            end
                        else
                            if isnothing(name)
                                println("### state, X -> $e, $y  [not fully implemented]")
                            else
                                println("### state, X -> $e, $y, :$name  [not fully implemented]")
                            end
                        end
                    end
                    ( :state_range, e) => let
                        if isnothing(name)
                            println("### state, $e, $x, $z")
                        else
                            println("### state, $e, $x, $z, :$name")
                        end
                    end
                    _                    => let
                        @show _t
                        @show _c
                        println("typeof(_c) = ", typeof(_c))
                    end
                end
            end
            :( $x <= $y <= $z) ||
            :( $x ≤  $y  ≤ $z) => let
                (_t, _c ) = constraint_type(y,
                                            _time_variable,
                                            _t0_variable,
                                            _tf_variable,
                                            _state_variable,
                                            _control_variable)
                @match ( _t, _c ) begin
                    ( :initial, nothing) => let
                        if isnothing(name)
                            println("### initial, $x, $z")
                        else
                            println("### initial, $x, $z, :$name")
                        end
                    end
                    ( :initial, a)  => let
                        if isnothing(name)
                            println("### initial, $_c, $x, $z")
                        else
                            println("### initial, $_c, $x, $z, :$name")
                        end
                    end
                    ( :final  , nothing) => let
                        if isnothing(name)
                            println("### final, $x, $z")
                        else
                            println("### final, $x, $z, :$name")
                        end
                    end
                    ( :final  , a) => let
                        if isnothing(name)
                            println("### final, $_c, $x, $z")
                        else
                            println("### final, $_c, $x, $z, :$name")
                        end
                    end
                    ( :boundary, e) => let
                        if isnothing(name)
                            println("### boundary, ( T0, X0, TF, XF) -> $_c, $x, $z   [not fully implemented]")
                        else
                            println("### boundary, ( T0, X0, TF, XF) -> $_c, $x, $z, :$name   [not fully implemented]")
                        end
                    end
                    ( :control_fun, e) => let
                        if e == _control_variable
                            if isnothing(name)
                                println("### control, $x, $z")
                            else
                                println("### control, $x, $z, :$name")
                            end
                        else
                            if isnothing(name)
                                println("### control, U -> $e, $x, $z  [not fully implemented]")
                            else
                                println("### control, U -> $e, $x, $z, :$name  [not fully implemented]")
                            end
                        end
                    end
                    ( :control_range, e) => let
                        if isnothing(name)
                            println("### control, $e, $x, $z")
                        else
                            println("### control, $e, $x, $z, :$name")
                        end
                    end
                    ( :state_fun, e) => let
                        if e == _state_variable
                            if isnothing(name)
                                println("### state, $x, $z")
                            else
                                println("### state, $x, $z, :$name")
                            end
                        else
                            if isnothing(name)
                                println("### state, X -> $e, $x, $z  [not fully implemented]")
                            else
                                println("### state, X -> $e, $x, $z, :$name  [not fully implemented]")
                            end
                        end
                    end
                    ( :state_range, e) => let
                        if isnothing(name)
                            println("### state, $e, $x, $z")
                        else
                            println("### state, $e, $x, $z, :$name")
                        end
                    end
                    _                    => let
                        @show _t
                        @show _c
                        println("typeof(_c) = ", typeof(_c))
                    end
                end
            end

        end
    end

    # 6/ objective
    (c, index) = _line_of_type( _parsed_code, e_objective_min)
    (c, index) = _line_of_type( _parsed_code, e_objective_max)

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
function _types_already_parsed( _pc::Array{_code}, types::_ctparser_line_type...)
    for c in _pc
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
function _type_and_var_already_parsed( _pc::Array{_code}, type::_ctparser_line_type, content::Any )
    count = 1
    for c in _pc
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
function _line_of_type( _pc::Array{_code},  type::_ctparser_line_type)
    count = 1
    for c in _pc
        if c.type == type
            return c, count
        end
        count += 1
    end
    return nothing, 0
end # _line_of_type

#
# verbose message: only print then level <= _verbose_threshold
#
# level == 0     -> always print
# level increase -> less print (mode debug)
#
function verbose(_verbose_threshold::Int, level::Int, args...)
    if _verbose_threshold >= level
        for x in args
            print(x)
        end
        if length(args) > 0
            print("\n")
        end
    end
end # function verbose

#
# (internal) print informations on each parsed lines
# activated when debug flag is passed to the macro @def
#
function _code_debug_info( _pc::Array{_code} )
    # COV_EXCL_START
    if size(_pc)[1] == 0
        # this never happend since everything is parsed
        println("=== No debug information from CtParser (empty code)")
        return
    end
    # COV_EXCL_STOP
    println("=== Debug information from CtParser:")
    count = 1
    for c in _pc
        println("Line number: $count") ; count += 1
        println("- current line: ", c.line |> remove_line_number_node)
        if c.line != c.initial_line
            println("- initial line: ", c.initial_line |> remove_line_number_node)
        end
        println("- content     : ", c.content |> remove_line_number_node)
        println("- info        : ", c.info)
        println("- code        : ", c.code)
        if !isnothing(c.name)
            println("- name        : ", c.name)
        end
        println("")
    end
end # code_debug_info



# COV_EXCL_START

#
# helpers to modify the parser behavior.
# useful for debugging/testing
# --------------------------------------

# WARNING: these functions are tricky and return sometimes bad results

#
# all these functions **MUST** be removed from final code
#
function _store_code_as_string(info::String, index::Integer)
    global _parsed_code
    global _generated_code

    _parsed_code[index].code = info
    push!(_generated_code, info)
end

#
# getter of a line of code (debug)
#
function get_parsed_line( i::Integer )
    global _parsed_code
    if i <= 0 || i > size(_parsed_code)[1]
        return false
    end
    return _parsed_code[i]
end

#
# print generated code as strings
#
function print_generated_code()
    global _generated_code

    if size(_generated_code)[1] == 0
        println("=== No code for this definition")
        return
    end
    println("=== Generated code")
    println("ocp = Model()")
    println.(_generated_code)
    return
end # print_generated_code

# COV_EXCL_STOP
