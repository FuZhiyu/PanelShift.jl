# PanelShift.jl

[![Build Status](https://github.com/fuzhiyu/PanelShift.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/fuzhiyu/PanelShift.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/fuzhiyu/PanelShift.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/fuzhiyu/PanelShift.jl)

This package provides convenient functions to lead&lag vectors with respect to a time vector. The time vector needs to be strictly increasing, but gaps are allowed. This is a common operation when dealing with panel data, where entities may have different missing periods. 

The key function in this package is `tlag` (`tlead`):
```julia
julia> t, v = [1;2;4], [1;2;3];
julia> tlag(t, v) # the default lag period is the unitary difference in t, here 1
3-element Vector{Union{Missing, Int64}}:
  missing
 1
  missing


julia> tlag(t, v, 2) # we can also specify lags using the third argument
3-element Vector{Union{Missing, Int64}}:
  missing
  missing
 2


julia> using Dates;
julia> t = [Date(2020,1,1); Date(2020,1,2); Date(2020,1,4)];
julia> tlag(t, [1, 2, 3]) # customized types of the time vector are also supported 
3-element Vector{Union{Missing, Int64}}:
  missing
 1
  missing


julia> tlag(t, [1, 2, 3], Day(2)) # specify two-day lags
3-element Vector{Union{Missing, Int64}}:
  missing
  missing
 2
```
Function `tlead` shifts the array in the opposite direction, and function `tshift` calls `tlag` when the period `n` is positive and vice versa.

For convenience (and to honor the name of the package), I also define functions `panellag`, `panellead` and `panelshift` to shift vectors in panel data. These functions are wrappers of `groupby`, `transform!` and `tshift`, e.g., 

```julia
function panellag!(df, id, t, x, newx, n=oneunit(df[1, t] - df[1, t]); checksorted=true)
    return transform!(groupby(df, id), [t, x] => ((t, x) -> tlag(t, x, n; checksorted=checksorted)) => newx)
end
```
It groups `df` by `id`, applies `tlag` to `x` with respect to `t`, and stores the lagged column in `df` under the name `newx`.

As an example:
```julia
julia> using DataFrames;
julia> df = DataFrame(
    t = [1;2;3;4; 1;3;4; 1;4; 1], 
    id = [1;1;1;1; 2;2;2; 3;3; 4],
    x = [1;2;3;4; 5;6;7; 8;9; 10]
);
julia> panellead!(df, :id, :t, :x, :Fx)

10×4 DataFrame
 Row │ t      id     x      Fx      
     │ Int64  Int64  Int64  Int64?  
─────┼──────────────────────────────
   1 │     1      1      1  missing 
   2 │     2      1      2        1
   3 │     3      1      3        2
  ⋮  │   ⋮      ⋮      ⋮       ⋮
   8 │     1      3      8  missing 
   9 │     4      3      9  missing 
  10 │     1      4     10  missing 
                      4 rows omitted
```
