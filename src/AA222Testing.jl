
"""
    AA222Testing

Testing framework for AA222 Spring 2020. Does not export any names but implements the following:

- `Test`: type for handling tests. First argument must be the expression to be evaluated (as an Expr).
Accepts keyword argument `weight`. Other keyword arguments go into an `:info` dict.

- `localtest`: prints the results of a test set so students can see how they're doing.

- `gradescope_output`: returns a NamedTuple in the format gradescope requires.
Run `json` on the result to get a json string save to a file.


## Example Usage
```
using AA222Testing: Test, runtests, gradescope_output
using JSON

tests = [Test(:(1 + 1 == 2), weight = 50, name = "Evaluate 1+1=2", number = "1.1", max_score = 50)
         Test(:(7.2 + 9.0 ≈ 16.2), weight = 50, name = "Evaluate 7.2 + 9.0 = 16.2", number = "1.2", max_score = 50)
        ]

runtests(tests)

json_out = json(gradescope_output(tests), 4)

```
"""
module AA222Testing



struct Error
    e
    backtrace
end
Base.show(io::IO, e::Error) = print(io, typeof(e.e))

Base.:*(::Error, n::Number) = zero(n)
Base.:*(n::Number, ::Error) = zero(n)

# @enum Result Pass Fail

# Base.:*(r::Result, n::Number) = r == Pass ? n : zero(n)
# Base.:*(n::Number, r::Result) = r == Pass ? n : zero(n)

# Performs a test in a try-catch and returns a result. Used in `runtest!` to fill a Test.result
function _test(ex::Expr)
    if ex.head != :call
        throw(ErrorException("Can only handle boolean expressions. Got incompatible expression:\n\t $ex"))
    end

    try
        return @eval Main $ex
    catch e
        return Error(e, catch_backtrace())
    end
end


######## A single Test object ########

mutable struct Test
    ex::Expr
    result
    weight::Float64
    info::Dict

    Test(ex; weight = 1, kwargs...) = new(ex, nothing, weight, Dict(kwargs...))
end

function runtest!(test::Test)
    res = _test(test.ex)
    test.result = res

    test.info[:score] = res * test.weight
    extra_data = get!(test.info, :extra_data, Dict())
    extra_data[:evalulated_expression] = string(test.ex)

    return test
end





######### These deal with a Vector of Tests (i.e. a testset) #########

function runtests(tests::Vector{Test})
    for t in tests
        Δt = @elapsed runtest!(t)
        t.info[:execution_time] = Δt
    end

    return tests
end

# TODO figure out how leaderboard could flexibly fit in to this
function gradescope_output(tests::Vector{Test})
    (score = sum(get(t.info, :score, 0) for t in tests),
     execution_time = sum(get(t.info, :execution_time, 0) for t in tests),
     visibility = "visible",
     extra_data = (language = "julia",),
     tests = getproperty.(tests, :info))
end



"""
    localtest(tests, show_errors = false)

For local evaluation of a series of tests. Prints out the results of each
test and, if `show_errors = true`, also any stacktraces encountered"
"""
function localtest(tests::Vector{Test}, show_errors = false)

    runtests(tests)

    got_error = false

    for (i, t) in enumerate(tests)
        r = t.result
        if r isa Error
            printstyled("Error in Test $i", bold = true, color=Base.error_color())
            if show_errors
                showerror(stdout, r.e, r.backtrace)
                println()
            else
                printstyled("; ", r.e, bold = true, color=Base.error_color())
                println()
                got_error = true
            end
        elseif r isa Bool
            r ? printstyled("Test $i Passed\n", bold = true, color=:green) :
            printstyled("Test $i Failed\n", bold = true, color=Base.error_color())
        end
    end
    if got_error
        @info "Error stacktraces supressed. Use argument `true` to see them."
    end
end

localtest(tests...; show_errors = false) = locatests(collect(tests), show_errors)

end #module