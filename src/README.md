# AA222Testing
Testing framework for AA222 Spring 2020. Does not export any names but implements the following:

- `Test`: type for handling tests. First argument must be the expression to be evaluated (as an `Expr`).
Accepts keyword argument `weight`. Other keyword arguments go into an `:info` dict.

- `localtest`: prints the results of a test set so students can see how they're doing.

- `gradescope_output`: returns a `NamedTuple` in the format gradescope requires.
Run `json` on the result to get a json string save to a file.

Note:
- test expressions are evaluated in `Main` with `@eval` so are not meant to test performance in any way.

## Example Usage
```julia
using AA222Testing: Test, runtests, gradescope_output
using JSON

tests = [Test(:(1 + 1 == 2), weight = 50, name = "Evaluate 1+1=2", number = "1.1", max_score = 50)
         Test(:(7.2 + 9.0 ≈ 16.2), weight = 50, name = "Evaluate 7.2 + 9.0 = 16.2", number = "1.2", max_score = 50)
        ]

runtests(tests)

write("./results/results.json", json(gradescope_output(tests), 4))