# AA222Testing
Testing framework for AA222 Spring 2020.

- `Test`: type for handling tests. First argument must be a function `f()` or `f!(info)` to be evaluated.
Any keyword arguments to the constructor go into an `:info` dict.

- `localtest`: prints the results of a test set so students can see how they're doing.

- `gradescope_output`: returns a `Dict` in the format gradescope requires. If a filename is given, writes that dict to the file as json.

## Example Usage
```julia
using AA222Testing

test_f(a, b) = () -> (f(a, b) == (a + b))

tests = [Test(test_f(1, 1), weight = 50, name = "Evaluate 1+1=2"),
         Test(test_f(7.2, 9.0), weight = 50, name = "Evaluate 7.2 + 9.0 = 16.2")]

runtests!(tests)

gradescope_output("./results/results.json", tests)
