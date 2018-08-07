
export check_function, check_method
export StabilityReport, is_stable

"""
    check_function(func, signatures, acceptable_instability=Dict())

Check that the function is stable under each of the given signatures.

Return an array of method signature-`StabilityReport` pairs from
[`check_method`](@ref).
"""
function check_function(func, signatures, acceptable_instability=Dict{Symbol, Type}())
    result = Tuple{Any, StabilityReport}[]
    for params in signatures
        push!(result, (params, check_method(func, params, acceptable_instability)))
    end
    result
end

"""
    check_method(func, signature, acceptable_instability=Dict())

Create a `StabilityReport` object describing the type stability of the method.

Compute non-concrete types of variables and return value, returning them in
a [`StabilityReport`](@ref) Object

`acceptable_instability`, if present, is a mapping of variables that are
allowed be non-concrete types.  `get` is called with the mapping, the
variable's symbol and `Bool` to get the variable's allowed type.  Additionally,
the return value is checked using `:return` as the symbol.

-`unstable_return::Type`: A supertype of allowed, non-concrete return types.
"""
#Based off julia's code_warntype
function check_method(func, signature, acceptable_instability=Dict{Symbol, Type}())
    function slots_used(ci, slotnames)
        used = falses(length(slotnames))
        scan_exprs!(used, ci.code)
        return used
    end

    function scan_exprs!(used, exprs)
        for ex in exprs
            if isa(ex, Slot)
                used[ex.id] = true
            elseif isa(ex, Expr)
                scan_exprs!(used, ex.args)
            end
        end
    end

    function var_is_stable(typ, name)
        (isleaftype(typ) && typ != Core.Box) ||
            begin
                (typ <: get(acceptable_instability, name, Bool))
            end
    end

    #loop over possible methods for the given argument types
    code = code_typed(func, signature)
    if length(code) == 0
        error("No methods found for $func matching $signature")
    elseif length(code) != 1
        warn("Mutliple methods for $func matching $signature")
    end

    unstable_vars_list = Array{Tuple{Symbol, Type}, 1}(0)
    unstable_ret = Nullable{Type}()

    for (src, rettyp) in code
        #check variables
        slotnames = Base.sourceinfo_slotnames(src)
        used_slotids = slots_used(src, slotnames)

        if isa(src.slottypes, Array)
            for i = 1:length(slotnames)
                if used_slotids[i]
                    name = Symbol(slotnames[i])
                    typ = src.slottypes[i]
                    if !var_is_stable(typ, name)
                        push!(unstable_vars_list, (name, typ))
                    end

                    #else likely optmized out
                end
            end
        else
            warn("Can't access slot types of CodeInfo")
        end

        if !var_is_stable(rettyp, :return)
            push!(unstable_vars_list, (:return, rettyp))
        end

        #TODO check body
    end

    return StabilityReport(unstable_vars_list)
end

"""
    StabilityReport()
    StabilityReport(unstable_variables::Vector{Tuple{Symbol, Type}})

Holds information about the stability of a method.

If `unstable_vars` is present, set the fields.  Otherwise, creates an empty set.

See [`is_stable`](@ref)
"""
struct StabilityReport
    "A list of unstable variables and their values"
    unstable_variables::Dict{Symbol, Type}

    StabilityReport(v::Dict{Symbol, Type}) = new(v)
end

StabilityReport() = StabilityReport(Dict{Symbol, Type}())
StabilityReport(vars) = StabilityReport(Dict{Symbol, Type}(vars))

function Base.:(==)(x::StabilityReport, y::StabilityReport)
    x.unstable_variables == y.unstable_variables
end

"""
    is_stable(report::StabilityReport)::Bool
    is_stable(reports::AbstractArray{Tuple{Any, StabilityReport}})::Bool

Check if the given [`StabilityReport`](@ref)s don't have any unstable types.
"""
is_stable(report::StabilityReport)::Bool = length(report.unstable_variables) == 0
is_stable(reports::AbstractArray{StabilityReport})::Bool = all(@. is_stable(reports))
is_stable(reports::Set{StabilityReport})::Bool = all(@. is_stable(reports))
