# TypeStability

This package provides functions to automate checking functions for type stability.  The checks are only run when enabled, which allows the function signatures that need to perform well to be located with the actual code without hurting performance.

### Example

```julia
julia> using TypeStability

julia> enable_inline_stability_checks(true)
true

julia> @stable_function [(Float64,)] function f(x)
                          if x > 0
                              x
                          else
                              Int(0)
                          end
                      end
f(Float64) is not stable
  return is of type Union{Float64, Int64}

julia> f
f (generic function with 1 method)

julia> @stable_function [(Float64,)] function g(x)
                          if x > 0
                              x
                          else
                             0.0
                          end
                      end

julia> g
g (generic function with 1 method)
```

