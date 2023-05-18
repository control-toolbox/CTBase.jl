#
# problem definition as a 'julia like' syntax


using MLStyle         # for parsing
using Printf

export @def0
export CtParserException
export print_generated_code

# only export then debugging
export get_parsed_line


#
# _code "class"
# -------------------------

# Parser exception (to normalize error output)
mutable struct CtParserException <: Exception
    msg::String
    CtParserException(msg::String) = new("@def0 parsing error: " * msg )
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
            _type == e_objective_max
            #
            # _content is:
            #     [ expression ]
            #
            # code.line should containt expression
            #
            new(_content[1], _type, _content, nothing, _line, _info, "")
        elseif _type == e_constraint
            #
            # _content is:
            #       [ :(==), x, y ]
            #    or [ :(<=), y, x, z ]
            #
            # code.line should containt y
            #
            new(_content[2], _type, _content, nothing, _line, _info, "")
        else
            #
            # for all other line types, code.initial_line == code.line
            #
            new(_line, _type, _content, nothing, _line, _info, "")
        end
    end
    function _code(_line, _type, _content, _info, _name)
        #
        # _content looks is:
        #       [ name, :(==), x, y ]
        #    or [ name, :(<=), y, x, z ]
        #
        # code.line    should containt y,
        # code.content should not contain name
        # code.name    should containt name
        #
        if _name isa Integer
            _name = "eq" * string(_name)
            #            new(_content[1], _type, _content, Symbol(_name), _line, _info, "")
            new(_content[3], _type, _content[2:end], Symbol(_name), _line, _info, "")
        elseif _name isa Expr
            _name = "eq" * string(_name)
            #            new(_content[1], _type, _content, Symbol(_name), _line, _info, "")
            new(_content[3], _type, _content[2:end], Symbol(_name), _line, _info, "")
        else
            #            new(_content[1], _type, _content, _name, _line, _info, "")
            new(_content[3], _type, _content[2:end], _name, _line, _info, "")
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
#_generated_code::Array{String} = [] # memorize generated code

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
function ctparser( prob::Expr; _syntax_only::Bool, _debug_mode::Bool,  _verbose_threshold::Integer )

    # start from scratch (may be modified later)
    global _parsed_code = []
    #global _generated_code = []

    #
    # FINAL CODE HERE !
    #
    # _parsed_code = []
    _generated_code::Array{String} = []    # memorize generated code

    # pass 1:
    #
    # - parse
    # - detect dupplicates
    # - store everything in _parsed_code
    #
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
                if _type_and_var_already_parsed( _parsed_code,  e_constraint, _c[2:end])[1]
                    return :(throw(CtParserException("constraint defined twice")))
                end
                push!(_parsed_code, _code( node, e_constraint, _c, "(temporary_1: named constraint)", _c[1]))
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
            e => let
                verbose(_verbose_threshold, 0, "CtParser error: cannot parse line (", node, ")")
                return :(throw(CtParserException("parsing error (phase 1)")))
            end
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
    push!(_generated_code, "ocp = Model()")

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
            codeline = quote time!(ocp,:final, $(esc(y))) end
            push!(_final_code, codeline)
            _parsed_code[index].info = "final time definition with $y"
            _store_code_as_string( "time!(ocp,:final, $y)", index, _generated_code)
            _parsed_code[t_index_0].info = "use $x as initial time variable"
            _parsed_code[t_index_0].code = "<none: included in time!() call>"
            @goto after_time
        end

        # is tf a variable ?
        if status_f
            _t0_variable = x
            codeline = quote time!(ocp,:initial, $(esc(x))) end
            push!(_final_code, codeline)
            _parsed_code[index].info = "initial time definition with $x"
            _store_code_as_string( "time!(ocp,:initial, $x)", index, _generated_code)
            _parsed_code[t_index_f].info = "use $y as final time variable"
            _parsed_code[t_index_f].code = "<none: included in time!() call>"
            @goto after_time
        end
        # nor t0 and tf are variables (in Main scope)
        _t0_variable = x
        _tf_variable = y

        codeline = quote time!(ocp, [ $(esc(x)), $(esc(y))] ) end
        push!(_final_code, codeline)
        _parsed_code[index].info = "time definition with [$x, $y]"
        _store_code_as_string( "time!(ocp, [$x, $y])", index, _generated_code)

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
        codeline = quote state!(ocp, $(esc(d))) end
        push!(_final_code, codeline)
        _parsed_code[index].info = "state vector ($_state_variable) of dimension $d"
        _store_code_as_string( "state!(ocp, $d)", index, _generated_code)
    end
    (c, index) = _line_of_type( _parsed_code, e_state_scalar)
    if c != nothing
        _state_variable = c.content[1]  # aka state name
        codeline = quote state!(ocp, 1) end
        push!(_final_code, codeline)
        _parsed_code[index].info = "state scalar ($_state_variable)"
        _store_code_as_string( "state!(ocp, 1)", index, _generated_code)
    end


    # 4/ call control!
    (c, index) = _line_of_type( _parsed_code, e_control_vector)
    if c != nothing
        _control_variable = c.content[1]  # aka control name
        d = c.content[2]  # aka dimention
        codeline = quote control!(ocp, $(esc(d))) end
        push!(_final_code, codeline)
        _parsed_code[index].info = "control vector ($_control_variable) of dimension $d"
        _store_code_as_string( "control!(ocp, $d)", index, _generated_code)
    end
    (c, index) = _line_of_type( _parsed_code, e_control_scalar)
    if c != nothing
        _control_variable = c.content[1]  # aka control name
        codeline = quote control!(ocp, 1) end
        push!(_final_code, codeline)
        _parsed_code[index].info = "control scalar ($_control_variable)"
        _store_code_as_string( "control!(ocp, 1)", index, _generated_code)
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

        # c.content contains:
        #
        #     [ :(==), x, y ]     (for x == y)
        # or  [ :(<=), y, x, z ]  (for x <= y <= z)
        #
        _type = c.content[1]   # :(==)  or :(<=)
        _expr = c.line         # contains y after unaliasing
        _name = c.name         # name::Symbol or nothing

        if _type == :(==)
            _v1 = c.content[3] # y  ( from x == y)
            _v2 = :nothing     #
        elseif _type == :(≤)
            _v1 = c.content[3] # x  ( from x <= y <= z)
            _v2 = c.content[4] # z
        else
            # COV_EXCL_START
            # should never happend
            verbose(_verbose_threshold, 0, "CtParser error: internal error on constraint (", c.line, ")")
            return :(throw(CtParserException("parsing error (phase 2)")))
            # COV_EXCL_STOP
        end

        (_ctype, _c ) = constraint_type(_expr,
                                    _time_variable,
                                    _t0_variable,
                                    _tf_variable,
                                    _state_variable,
                                    _control_variable)

        # for boundary arguments:  pretty print / code
        _pprt_tuple = "(var\"$_time_variable#0\", var\"$_state_variable#0\", var\"$_time_variable#f\", var\"$_state_variable#f\")"
        _code_tuple = ( Symbol(_time_variable,  "#0"),
                        Symbol(_state_variable, "#0"),
                        Symbol(_time_variable,  "#f"),
                        Symbol(_state_variable, "#f"))

        if _ctype == :dynamics
            # must modify the function
            _dynamic_fun = replace_call(
                replace_call(c.content[3],
                             _state_variable,
                             _time_variable,
                             _state_variable),
                _control_variable,
                _time_variable,
                _control_variable)
        end
        _parsed_code[i].info = "constraint $_ctype"

        @match ( _ctype, _c, _type, isnothing(_name)) begin

            # initial
            ( :initial, nothing, :(==), true) => let
                codeline = quote constraint!(ocp, :initial, $(esc(_v1))) end
                push!(_final_code, codeline)
                _store_code_as_string( "constraint!(ocp, :initial, $_v1)", i, _generated_code)
            end
            ( :initial, nothing, :(≤) , true) => let
                codeline = quote constraint!(ocp, :initial, $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string( "constraint!(ocp, :initial, $_v1, $_v2)", i, _generated_code)
            end
            ( :initial, nothing, :(==), false) => let
                codeline = quote constraint!(ocp, :initial, $(esc(_v1)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string( "constraint!(ocp, :initial, $_v1, :$_name)", i, _generated_code)
            end
            ( :initial, nothing, :(≤), false) => let
                codeline = quote constraint!(ocp, :initial, $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string( "constraint!(ocp, :initial, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            ( :initial, a, :(==), true)  => let
                codeline = quote constraint!(ocp, :initial, $(esc(a)), $(esc(_v1))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :initial, $a, $_v1)", i, _generated_code)
            end
            ( :initial, a, :(≤), true)  => let
                codeline = quote constraint!(ocp, :initial, $(esc(a)), $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :initial, $a, $_v1, $_v2)", i, _generated_code)
            end
            ( :initial, a, :(==), false)  => let
                codeline = quote constraint!(ocp, :initial, $(esc(a)), $(esc(_v1)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :initial, $a, $_v1, :$_name)", i, _generated_code)
            end
            ( :initial, a, :(≤), false)  => let
                codeline = quote constraint!(ocp, :initial, $(esc(a)), $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :initial, $a, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            # final
            ( :final, nothing, :(==), true) => let
                codeline = quote constraint!(ocp, :final, $(esc(_v1))) end
                push!(_final_code, codeline)
                _store_code_as_string( "constraint!(ocp, :final, $_v1)", i, _generated_code)
            end
            ( :final, nothing, :(≤) , true) => let
                codeline = quote constraint!(ocp, :final, $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string( "constraint!(ocp, :final, $_v1, $_v2)", i, _generated_code)
            end
            ( :final, nothing, :(==), false) => let
                codeline = quote constraint!(ocp, :final, $(esc(_v1)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string( "constraint!(ocp, :final, $_v1, :$_name)", i, _generated_code)
            end
            ( :final, nothing, :(≤), false) => let
                codeline = quote constraint!(ocp, :final, $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string( "constraint!(ocp, :final, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            ( :final, a, :(==), true)  => let
                codeline = quote constraint!(ocp, :final, $(esc(a)), $(esc(_v1))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :final, $a, $_v1)", i, _generated_code)
            end
            ( :final, a, :(≤), true)  => let
                codeline = quote constraint!(ocp, :final, $(esc(a)), $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :final, $a, $_v1, $_v2)", i, _generated_code)
            end
            ( :final, a, :(==), false)  => let
                codeline = quote constraint!(ocp, :final, $(esc(a)), $(esc(_v1)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :final, $a, $_v1, :$_name)", i, _generated_code)
            end
            ( :final, a, :(≤), false)  => let
                codeline = quote constraint!(ocp, :final, $(esc(a)), $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :final, $a, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            # boundary
            ( :boundary, a, :(==), true) => let
                #_lambda = Expr( :->, _code_tuple, a)
                _lambda = :((Symbol("t#0"), Symbol("x#0"), Symbol("t#f"), Symbol("x#f"))->var"x#f" - tf * var"x#0") |> remove_line_number_node
                println("=== dump a")
                Meta.dump(a)
                println("=== dump lambda")
                Meta.dump(_lambda)
                _lambda = :( (QuoteNode(Symbol("t#0")), QuoteNode(Symbol("x#0")), QuoteNode(Symbol("t#f")), QuoteNode(Symbol("x#f")))->var"x#f" - tf * var"x#0") |> remove_line_number_node
                Meta.dump(_lambda)
                codeline = quote constraint!(ocp, :boundary, $(esc(_lambda)), $(esc(_v1))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :boundary, $_pprt_tuple -> $a, $_v1)   # not implemented", i, _generated_code)
            end
            ( :boundary, a, :(≤), true) => let
                _store_code_as_string("constraint!(ocp, :boundary, $_pprt_tuple -> $a, $_v1, $_v2)   # not implemented", i, _generated_code)
            end
            ( :boundary, a, :(==), false) => let
                _store_code_as_string("constraint!(ocp, :boundary, $_pprt_tuple -> $a, $_v1, :$_name)   # not implemented", i, _generated_code)
            end
            ( :boundary, a, :(≤), false) => let
                _store_code_as_string("constraint!(ocp, :boundary, $_pprt_tuple -> $a, $_v1, $_v2, :$_name)   # not implemented", i, _generated_code)
            end

            # control
            ( :control_fun, a, :(==), true) => let
                codeline = quote constraint!(ocp, :control, $(esc(_control_variable)) -> $(esc(a)), $(esc(_v1))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :control, $_control_variable -> $a, $_v1)", i, _generated_code)
            end
            ( :control_fun, a, :(≤), true) => let
                codeline = quote constraint!(ocp, :control, $(esc(_control_variable)) -> $(esc(a)), $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :control, $_control_variable -> $a, $_v1, $_v2)", i, _generated_code)
            end
            ( :control_fun, a, :(==), false) => let
                codeline = quote constraint!(ocp, :control, $(esc(_control_variable)) -> $(esc(a)), $(esc(_v1)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :control, $_control_variable -> $a, $_v1, :$_name)", i, _generated_code)
            end
            ( :control_fun, a, :(≤), false) => let
                codeline = quote constraint!(ocp, :control, $(esc(_control_variable)) -> $(esc(a)), $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :control, $_control_variable -> $a, $_v1, $_v2, :$_name)", i, _generated_code)
           end

            # # not allowed:  Please choose in [ :initial, :final ] or check the arguments of the constraint! method.
            # ( :control_range, nothing, :(==), true) => let
            #     codeline = quote constraint!(ocp, :control, $(esc(_v1))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("constraint!(ocp, :control, $_v1)", i, _generated_code)
            # end
            ( :control_range, nothing, :(≤), true) => let
                codeline = quote constraint!(ocp, :control, $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :control, $_v1, $_v2)", i, _generated_code)
            end
            # not allowed:  Please choose in [ :initial, :final ] or check the arguments of the constraint! method.
            # ( :control_range, nothing, :(==), false) => let
            #     codeline = quote constraint!(ocp, :control, $(esc(_v1)), $(QuoteNode(_name))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("constraint!(ocp, :control, $_v1, :$_name)", i, _generated_code)
            # end
            ( :control_range, nothing, :(≤), false) => let
                codeline = quote constraint!(ocp, :control, $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :control, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            # not allowed:  Please choose in [ :initial, :final ] or check the arguments of the constraint! method.
            # ( :control_range, a, :(==), true) => let
            #     codeline = quote constraint!(ocp, :control, $(esc(a)), $(esc(_v1))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("constraint!(ocp, :control, $a, $_v1)", i, _generated_code)
            # end
            ( :control_range, a, :(≤), true) => let
                codeline = quote constraint!(ocp, :control, $(esc(a)), $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :control, $a, $_v1, $_v2)", i, _generated_code)
            end
            # not allowed:  Please choose in [ :initial, :final ] or check the arguments of the constraint! method.
            # ( :control_range, a, :(==), false) => let
            #     codeline = quote constraint!(ocp, :control, $(esc(a)), $(esc(_v1)), $(QuoteNode(_name))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("constraint!(ocp, :control, $a, $_v1, :$_name)", i, _generated_code)
            # end
            ( :control_range, a, :(≤), false) => let
                codeline = quote constraint!(ocp, :control, $(esc(a)), $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :control, $a, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            # state
            ( :state_fun, a, :(==), true) => let
                codeline = quote constraint!(ocp, :state, $(esc(_state_variable)) -> $(esc(a)), $(esc(_v1))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :state, $_state_variable -> $a, $_v1)", i, _generated_code)
            end
            ( :state_fun, a, :(≤), true) => let
                codeline = quote constraint!(ocp, :state, $(esc(_state_variable)) -> $(esc(a)), $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :state, $_state_variable -> $a, $_v1, $_v2)", i, _generated_code)
            end
            ( :state_fun, a, :(==), false) => let
                codeline = quote constraint!(ocp, :state, $(esc(_state_variable)) -> $(esc(a)), $(esc(_v1)), $(QuoteNode(_name))) end
               push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :state, $_state_variable -> $a, $_v1, :$_name)", i, _generated_code)
            end
            ( :state_fun, a, :(≤), false) => let
                codeline = quote constraint!(ocp, :state, $(esc(_state_variable)) -> $(esc(a)), $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :state, $_state_variable -> $a, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            # # not allowed:  Please choose in [ :initial, :final ] or check the arguments of the constraint! method.
            # ( :state_range, nothing, :(==), true) => let
            #     codeline = quote constraint!(ocp, :state, $(esc(_v1))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("constraint!(ocp, :state, $_v1)", i, _generated_code)
            # end
            ( :state_range, nothing, :(≤), true) => let
                codeline = quote constraint!(ocp, :state, $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :state, $_v1, $_v2)", i, _generated_code)
            end
            # not allowed:  Please choose in [ :initial, :final ] or check the arguments of the constraint! method.
            # ( :state_range, nothing, :(==), false) => let
            #     codeline = quote constraint!(ocp, :state, $(esc(_v1)), $(QuoteNode(_name))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("constraint!(ocp, :state, $_v1, :$_name)", i, _generated_code)
            # end
            ( :state_range, nothing, :(≤), false) => let
                codeline = quote constraint!(ocp, :state, $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :state, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            # not allowed:  Please choose in [ :initial, :final ] or check the arguments of the constraint! method.
            # ( :state_range, a, :(==), true) => let
            #     codeline = quote constraint!(ocp, :state, $(esc(a)), $(esc(_v1))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("constraint!(ocp, :state, $a, $_v1)", i, _generated_code)
            # end
            ( :state_range, a, :(≤), true) => let
                codeline = quote constraint!(ocp, :state, $(esc(a)), $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :state, $a, $_v1, $_v2)", i, _generated_code)
            end
            # not allowed:  Please choose in [ :initial, :final ] or check the arguments of the constraint! method.
            # ( :state_range, a, :(==), false) => let
            #     codeline = quote constraint!(ocp, :state, $(esc(a)), $(esc(_v1)), $(QuoteNode(_name))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("constraint!(ocp, :state, $a, $_v1, :$_name)", i, _generated_code)
            # end
            ( :state_range, a, :(≤), false) => let
                codeline = quote constraint!(ocp, :state, $(esc(a)), $(esc(_v1)), $(esc(_v2)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :state, $a, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            # mixed
            ( :mixed, a, :(==), true) => let
                codeline = quote constraint!(ocp, :mixed, ($(esc(_state_variable)), $(esc(_control_variable))) -> $(esc(a)), $(esc(_v1))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :mixed, ($_state_variable, $_control_variable) -> $a, $_v1)", i, _generated_code)
            end
            ( :mixed, a, :(≤), true) => let
                codeline = quote constraint!(ocp, :mixed, ($(esc(_state_variable)), $(esc(_control_variable))) -> $(esc(a)), $(esc(_v1)), $(esc(_v2))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :mixed, ($_state_variable, $_control_variable) -> $a, $_v1, $_v2)", i, _generated_code)
            end
            ( :mixed, a, :(==), false) => let
                codeline = quote constraint!(ocp, :mixed, ($(esc(_state_variable)), $(esc(_control_variable))) -> $(esc(a)), $(esc(_v1)), $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :mixed, ($_state_variable, $_control_variable) -> $a, $_v1, :$_name)", i, _generated_code)
            end
            ( :mixed, a, :(≤), false) => let
                codeline = quote constraint!(ocp, :mixed, ($(esc(_state_variable)), $(esc(_control_variable))) -> $(esc(a)), $(esc(_v1)), $(esc(_v2)),  $(QuoteNode(_name))) end
                push!(_final_code, codeline)
                _store_code_as_string("constraint!(ocp, :mixed, ($_state_variable, $_control_variable) -> $a, $_v1, $_v2, :$_name)", i, _generated_code)
            end

            # dynamics
            ( :dynamics, a, :(==), true) => let
                codeline = quote dynamics!(ocp, ($(esc(_state_variable)), $(esc(_control_variable))) -> $(esc(_dynamic_fun))) end
                push!(_final_code, codeline)
                _store_code_as_string("dynamics!(ocp, ($_state_variable, $_control_variable) -> $_dynamic_fun)", i, _generated_code)
            end
            # named dynamics not allowed
            # ( :dynamics, a, :(==), false) => let
            #     codeline = quote dynamics!(ocp, ($(esc(_state_variable)), $(esc(_control_variable))) -> $(esc(_dynamic_fun)), $(QuoteNode(_name))) end
            #     push!(_final_code, codeline)
            #     _store_code_as_string("dynamics!(ocp, ($_state_variable, $_control_variable) -> $_dynamic_fun, :$_name)", i, _generated_code)
            # end

            # error may still happend in some case (ex: x'(t) ≤ xxx)
            # this cannot be detected at phase 1
            _                    => let
                verbose(_verbose_threshold, 0, "CtParser error: cannot parse line or unallowed expression (", c.initial_line, ")")
                return :(throw(CtParserException("parsing error (phase 2)")))
            end
        end
    end

    # 6/ objective
    (c, index) = _line_of_type( _parsed_code, e_objective_min)
    (c, index) = _line_of_type( _parsed_code, e_objective_max)

    # x) final lines. Store ctparser internals into the returned object
    push!(_final_code, :(ocp.defined_with_macro = true))
    push!(_final_code, :(ocp.generated_code = $_generated_code))

    # return the created ocp object
    push!(_final_code, :(ocp))

    # concatenate all code as a simple block and return it
    e = Expr(:block, _final_code...)

end # macro @def0

macro def0( args... )
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

        return :(throw(CtParserException("bad option for @def0 (allowed: syntax_only=true, debug=true, verbose_threshold=n)")))
    end

    # call ctparser on last arg
    e = args[end]

    if ! (e isa Expr)
        return :(throw(CtParserException("input must be an Expr")))
    end

    # delegate work to the parsing function
    ctparser(e;
             _syntax_only=_syntax_only,
             _debug_mode=_debug_mode,
             _verbose_threshold = _verbose_threshold
             )
end

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
# activated when debug flag is passed to the macro @def0
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

"""
$(TYPEDSIGNATURES)

Display code substitution made by the @def0 macro
"""
function print_generated_code(ocp::OptimalControlModel)
    if ocp.defined_with_macro == false
        println("This OptimalControlModel has not been created with @def0 parser.")
        return false
    else
        for i ∈ ocp.generated_code
            println(i)
        end
        return true
    end
end

# type of input lines
@enum _ctparser_line_type e_time e_state_scalar e_state_vector e_control_scalar e_control_vector e_constraint e_named_constraint e_alias e_objective_min e_objective_max e_variable

"""
$(TYPEDSIGNATURES)

Figure the type of parsed line passed as argument

Returns a tuple (_type, Array{Any} )

Example:
"""
input_line_type(e) =
    @match e begin
        :($t ∈ [ $a, $b ], time)   => (e_time, [t, a, b])
        :($s ∈ R^$d, state )       => (e_state_vector, [s, d])
        :($s ∈ R², state )         => (e_state_vector, [s, 2])
        :($s ∈ R³, state )         => (e_state_vector, [s, 3])
        :($s ∈ R⁴, state )         => (e_state_vector, [s, 4])
        :($s ∈ R⁵, state )         => (e_state_vector, [s, 5])
        :($s ∈ R⁶, state )         => (e_state_vector, [s, 6])
        :($s ∈ R⁷, state )         => (e_state_vector, [s, 7])
        :($s ∈ R⁸, state )         => (e_state_vector, [s, 8])
        :($s ∈ R⁹, state )         => (e_state_vector, [s, 9])
        :($s[$d], state )          => (e_state_vector, [s, d])
        :($s ∈ R, state )          => (e_state_scalar, [s])
        :($s, state )              => (e_state_scalar, [s])
        :($s ∈ R^$d, control )     => (e_control_vector, [s, d])
        :($s ∈ R², control )       => (e_control_vector, [s, 2])
        :($s ∈ R³, control )       => (e_control_vector, [s, 3])
        :($s ∈ R⁴, control )       => (e_control_vector, [s, 4])
        :($s ∈ R⁵, control )       => (e_control_vector, [s, 5])
        :($s ∈ R⁶, control )       => (e_control_vector, [s, 6])
        :($s ∈ R⁷, control )       => (e_control_vector, [s, 7])
        :($s ∈ R⁸, control )       => (e_control_vector, [s, 8])
        :($s ∈ R⁹, control )       => (e_control_vector, [s, 9])
        :($s[$d], control )        => (e_control_vector, [s, d])
        :($s ∈ R, control )        => (e_control_scalar, [s])
        :($s, control )            => (e_control_scalar, [s])
        :($t ∈ R, variable )       => (e_variable, [t])
        :($t, variable )           => (e_variable, [t])
        :($a = $b)                 => (e_alias, [a, b])
        :($a -> begin min end)     => (e_objective_min, [a]) # debug: not allowed, remove
        :($a → min)                => (e_objective_min, [a])
        :($a -> begin max end)     => (e_objective_max, [a]) # debug: not allowed, remove
        :($a → max)                => (e_objective_max, [a])
        :($x == $y => ($n))        => (e_named_constraint, [n, :(==), x, y])
        :($x <= $y <= $z => ($n))  => (e_named_constraint, [n, :(≤),  y, x, z])
        :($x ≤  $y ≤  $z => ($n))  => (e_named_constraint, [n, :(≤),  y, x, z])
        :($x == $y , ($n))         => (e_named_constraint, [n, :(==), x, y])
        :($x <= $y <= $z, ($n))    => (e_named_constraint, [n, :(≤),  y, x, z])
        :($x ≤  $y ≤  $z, ($n))    => (e_named_constraint, [n, :(≤),  y, x, z])
        :($x == $y)                => (e_constraint,       [:(==),    x, y])
        :($x <= $y <= $z)          => (e_constraint,       [:(≤),     y, x, z])
        :($x ≤  $y ≤  $z)          => (e_constraint,       [:(≤),     y, x, z])
        _                          => (:other , [])
    end

# COV_EXCL_START

#
# helpers to modify the parser behavior.
# useful for debugging/testing
# --------------------------------------

# WARNING: these functions are tricky and return sometimes bad results

#
# all these functions **MUST** be removed from final code
#
function _store_code_as_string(info::String, index::Integer, generated_code::Array{String})
    global _parsed_code

    _parsed_code[index].code = info
    push!(generated_code, info)
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

# COV_EXCL_STOP
