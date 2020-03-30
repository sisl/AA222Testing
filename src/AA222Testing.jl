
module AA222Testing

using JSON

export LEADERBOARD
export Test
export set_stdout_visibility, set_leaderboard_value!, runtest!, runtests!, localtest, gradescope_output, metadata

# GLOBALS

# These have non-conventional type names so that their string output match the gradescope expected strings
@enum VisibilityMode hidden after_due_date after_published visible

const LEADERBOARD = []
const STDOUT_VIS = Ref(hidden)

stdout_visibility() = STDOUT_VIS.x

set_stdout_visibility(mode::VisibilityMode) = (STDOUT_VIS[] = mode)

######### Leaderboard handling #########
# leaderboard entries are named tuples
set_leaderboard_value!(name, value, order = "desc") = push!(LEADERBOARD, LeaderboardEntry(name, value, order))

mutable struct LeaderboardEntry
    name::String
    value::Union{Nothing, <:Number, String}
    order::String
end
LeaderboardEntry(name, value) = LeaderboardEntry(name, value, "desc")



"""
    metadata()
    metadata(path)

Retrieves the submission metadata from a json file as a `Dict`. See `https://gradescope-autograders.readthedocs.io/en/latest/submission_metadata/` for the metadata format.
"""
metadata(path = "/autograder/submission_metadata.json") = JSON.parsefile(path)



"""
    Test(f; kwargs...)

A Test object. when the test is run with `runtest!`, evaluates the function `f`.

Keyword arguments passed to the constructor go into the `Dict` `test.info`, which is eventually saved in the `tests` array of the output.
If `f` is a single argument function, the input `x` to `f(x)` is the dictionary `test.info`.
This is so calculations performed during the test `f` can be used to calculate e.g. the test score or evaluation time.
`f` may also be a no-argument function. In both cases, `f` must return a boolean indicating whether the test passed or not.
"""
mutable struct Test
    f::Function
    result::Union{Bool, Nothing}
    info::Dict

    function Test(g; weight = 1, kwargs...)
        info = Dict{Symbol, Any}(kwargs...)
        info[:max_score] = get(info, :max_score, weight)

        if hasmethod(g, (Dict,))
            # turn f into a closure over the info dict
            f = () -> g(info)
        elseif hasmethod(g, ())
            f = g
        else
            error("test.f does not have a method matching f() or f(::Dict).")
        end

        new(f, nothing, info)
    end
end

function runtest!(test::Test)
    info = test.info

    # reset if previously run
    if haskey(info, :output)
        pop!(info, :output)
    end
    info[:score] = nothing

    try
        test.result = test.f()
        # Check if the score was written into during test execution. If not it should
        # be the test result*total
        if isnothing(info[:score])
            info[:score] = test.result * get(info, :max_score, 1)
        end

    catch e
        test.result = false # auto-fail
        # write error message to output TODO: could the stacktrace reveal any info?
        info[:output] = sprint(showerror, e, catch_backtrace())
        info[:score] = 0

        # Print the error to the console if the visibility mode is set to allow it
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

function gradescope_output(tests::Vector{<:Dict}; leaderboard = false, kwargs...)
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

function gradescope_output(filename::AbstractString, tests; leaderboard = false, kwargs...)
    output = gradescope_output(tests; leaderboard=leaderboard, kwargs...)
    write(filename, json(output, 4))
end


############### LOCALTEST ###############

"""
    localtest(tests[; show_errors = true])

For local evaluation of a series of tests. Prints out the results of each
test and, if `show_errors = true`, also any stacktraces encountered"
"""
function localtest(tests::Vector{Test}; show_errors = true)
    vis = stdout_visibility()
    set_stdout_visibility(show_errors ? visible : hidden)

    for (i, t) in enumerate(tests)
        runtest!(t)
        if t.result
            printstyled("Test $i Passed\n", bold = true, color=:green)
        else
            printstyled("Test $i Failed\n", bold = true, color=Base.error_color())
        end
    end

    # Reset the visibility mode in case we changed it
    set_stdout_visibility(vis)
end

localtest(tests...; show_errors = false) = locatests(collect(tests), show_errors)

end #module