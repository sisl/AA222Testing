
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

# GLOBALS

# These have non-conventional type names so that their string output match the gradescope expected strings
@enum VisibilityMode hidden after_due_date after_published visible

const LEADERBOARD = []
const STDOUT_VIS = Ref(hidden)

stdout_visibility() = STDOUT_VIS.x

set_stdout_visibility(mode::VisibilityMode) = (STDOUT_VIS[] = mode)

######### Leaderboard handling #########
# leaderboard entries are named tuples
add_leaderboard!(name, value, order = "desc") = push!(LEADERBOARD, (name = name, value = value, order = order))


"""
    metadata()
    metadata(path)

Retrieves the submission metadata from a json file as a `Dict`. See `https://gradescope-autograders.readthedocs.io/en/latest/submission_metadata/` for the metadata format.
"""
metadata(path = "/autograder/submission_metadata.json") = JSON.parsefile(path)



"""
    Test(f!; kwargs...)

A Test object. when the test is run with `runtests!`, evaluates the function `f!`, which must be a
single argument function. The input x to `f!(x)` in `runtest!(test)` is the dictionary `test.info`
Any keyword arguments given to the constructor also go into the dictionary, which is eventually saved in the `tests` array of the output.
"""
mutable struct Test
    f::Function
    result::Union{Bool, Nothing}
    info::Dict

    function Test(f; weight = 1, kwargs...)
        info = Dict{Symbol, Any}(kwargs...)
        info[:max_score] = weight

        new(f, nothing, info)
    end
end

function runtest!(test::Test)
    info = test.info

    # reset if previously run
    info[:output] = nothing
    info[:score] = nothing

    if hasmethod(test.f, (Dict,))
        input = tuple(info)
    elseif hasmethod(test.f, ())
        input = tuple()
    else
        # Intentionally raise an error *outside* the try-catch so that the autograder itself fails.
        # This sort of error has nothing to do with the submission and is the fault of the test writer.
        error("test.f does not have a method matching f() or f(::Dict)")
    end

    try
        test.result = test.f(input...)
        if isnothing(info[:score])
            info[:score] = test.result * get(info, :max_score, 1)
        end

    catch e
        test.result = false # auto-fail
        # write error message to output
        info[:output] = sprint(showerror, e, catch_backtrace())
        info[:score] = 0

        # In case we're local, we want to see the error output. If we're running on gradescope,
        # printouts are private anyhow so it makes no difference
        if stdout_visibility() == visible
            showerror(stdout, e, catch_backtrace())
            println()
        end
    end
    return test
end


runtests!(tests::Vector{Test}) = runtest!.(tests)




######### These deal with the formatted output #########


function gradescope_output(tests::Vector{Test}; leaderboard = false, kwargs...)
    for t in tests
        if isnothing(t.result)
            runtest!(t)
        end
    end

    infos = getproperty.(tests, :info)

    gradescope_output(infos; leaderboard = leaderboard, kwargs...)
end

function gradescope_output(tests::Vector; leaderboard = false, kwargs...)
    output = Dict(kwargs...)
    output[:tests] = tests
    output[:score] = sum(t[:score] for t in tests)

    extra_data = get!(output, :extra_data, Dict())
    extra_data[:language] = "julia"
    output[:stdout_visibility] = stdout_visibility()

    if leaderboard
        output[:leaderboard] = copy(LEADERBOARD)
    end

    return output
end




############### LOCALTEST ###############

"""
    localtest(tests[; show_errors = true])

For local evaluation of a series of tests. Prints out the results of each
test and, if `show_errors = true`, also any stacktraces encountered"
"""
function localtest(tests::Vector{Test}; show_errors = true)
    set_stdout_visibility(show_errors ? visible : hidden)

    for (i, t) in enumerate(tests)
        runtest!(t)
        if t.result
            printstyled("Test $i Passed\n", bold = true, color=:green)
        else
            printstyled("Test $i Failed\n", bold = true, color=Base.error_color())
        end
    end
end

localtest(tests...; show_errors = false) = locatests(collect(tests), show_errors)

end #module