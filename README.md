# AA222Testing
Testing framework for AA222 Spring 2020.

- `Test`: type for handling tests. First argument must be a function `f()` or `f!(info)` to be evaluated.
Any keyword arguments to the constructor go into an `:info` dict.

- `localtest`: prints the results of a test set so students can see how they're doing.

- `gradescope_output`: returns a `Dict` in the format gradescope requires. If a filename is given, writes that dict to the file as json.

## Usage

### Basic Example
```julia
using AA222Testing

f(a, b) = a + b

test_f(a, b) = () -> (f(a, b) == (a + b))

tests = [Test(test_f(1, 1), weight = 50, name = "Evaluate 1+1=2"),
         Test(test_f(7.2, 9.0), weight = 50, name = "Evaluate 7.2 + 9.0 = 16.2")]

runtests!(tests)

gradescope_output("./results/results.json", tests)
```

The first argument to a `Test` is a zero argument or one argument function that evaluates to a boolean (`true` means the test passes). Also accepts the keywords `weight` or `max_score` (interchangeably) to determine how much a test is worth. Any other keywords go into a `Dict` accessible as `test.info`, which will be used to construct the json output object (e.g. `name`, `number`, `visibility`, etc.). If `test.f` is a one-argument function, that argument is by definition the `info` dict.
#### Ex:
```julia
function test_func(info)

    # Lets say we're timing some computation:
    delta_t = @elapsed evaluate_something(something)
    info[:elapsed_time] = delta_t
    
    # We can determine whether the student passes:
    if delta_t < 1.0
        pass = true
        
        # And we want to tell the student something about it in either case:
        info[:output] = "Great job! Your submission only took $delta_t seconds."
    else
        pass = false
        info[:output] = "Your submission only took $delta_t seconds, which isn't enough for credit"
    end
    
    # Note that we return `pass` at the end, which determines whether
    this test receives credit or not
    return pass
end
```

### Partial Credit
If the `test.f` edits the `:score` fields of `test.info`, this supercedes the return of the function.
