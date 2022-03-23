module PanelShift

using DataFrames
using ArgCheck
export tlag!, tlag, tlead!, tlead, tshift
export panellag!, panellead!, panelshift!

function tlag!(nxv, tv, xv, n=oneunit(tv[1] - tv[1]); checksorted=true)
    @argcheck (n > zero(n)) "n has to be strictly positive."
    if checksorted
        @argcheck issorted(tv; lt=<=) "The time vector is not strictly increasing!"
    end
    T = length(tv)
    @argcheck length(xv) == T "xv and tv have different lenths!"
    local j = 0
    for i in 1:T
        lagt = tv[i] - n
        # find the largest t that is no greater than lagt
        while true
            if tv[j + 1] <= lagt
                j += 1
            else
                break
            end
        end
        if j > 0 && tv[j] == lagt
            nxv[i] = xv[j]
        else
            nxv[i] = missing
        end
    end
    return nxv
end

function tlead!(nxv, tv, xv, n=oneunit(tv[1] - tv[1]); checksorted=true)
    @argcheck (n > zero(n)) "n has to be strictly positive."
    if checksorted
        @argcheck issorted(tv; lt=<=) "The time vector is not strictly increasing!"
    end
    T = length(tv)
    @argcheck length(xv) == T "xv and tv have different lenths!"
    local j = T + 1
    for i in T:-1:1
        leadt = tv[i] + n
        # find the smallest t that is no smaller than leadt
        while true
            if tv[j - 1] >= leadt
                j -= 1
            else
                break
            end
        end
        if j <= T && tv[j] == leadt
            nxv[i] = xv[j]
        else
            nxv[i] = missing
        end
    end
    return nxv
end

"""
    tlag(tv, xv, n = oneunit(tv[1] - tv[1]); checksorted=true)

Lag vector `xv` by `n` with respect to time vector `tv`. Gaps in `tv` is allowed.

The type of `n` should be consistent with `tv` for arithmetic. For example, 
if `tv` is a Date vector, then `n` should be a `Period` e.g. `Day(2)`. By default, 
`n` is set as the unitary difference in `tv`.

Time vector `tv` has to be strictly increasing. This requirement is checked by default. 
Users can turn off this behavior for performance-sensitive codes by 
setting `checksorted=false`.

# Examples
```jldoctest
julia> tlag([1;2;4], [4,5,6], 1)
3-element Vector{Union{Missing, Int64}}:
  missing
 4
  missing
```

```jldoctest
julia> tlag([Date(2020);Date(2022);Date(2024)], [4,5,6], Year(2))
3-element Vector{Union{Missing, Int64}}:
  missing
 4
 5
```

See also `tlead`, `tshift`.
"""
function tlag(tv, xv, n=oneunit(tv[1] - tv[1]); checksorted=true)
    nxv = allowmissing(similar(xv))
    return tlag!(nxv, tv, xv, n; checksorted=checksorted)
end

"""
    tlead(tv, xv, n = oneunit(tv[1] - tv[1]); checksorted=true)

Lead (forward) vector `xv` by `n` with respect to time vector `tv`. Gaps in `tv` is allowed.

The type of `n` should be consistent with `tv` for arithmetic. For example, 
if `tv` is a Date vector, then `n` should be a `Period` e.g. `Day(2)`. By default, 
`n` is set as the unitary difference in `tv`.

Time vector `tv` has to be strictly increasing. This requirement is checked by default. 
Users can turn off this behavior for performance-sensitive codes by 
setting `checksorted=false`.

# Examples
```jldoctest
julia> tlead([1;2;4], [4,5,6], 1)
3-element Vector{Union{Missing, Int64}}:
 5
  missing
  missing
```

```jldoctest
julia> tlead([Date(2020);Date(2022);Date(2024)], [4,5,6], Year(2))
3-element Vector{Union{Missing, Int64}}:
 5
 6
  missing
```

See also `tlag`, `tshift`.
"""
function tlead(tv, xv, n=oneunit(tv[1] - tv[1]); checksorted=true)
    nxv = allowmissing(similar(xv))
    return tlead!(nxv, tv, xv, n; checksorted=checksorted)
end


"""
    tshift(tv, xv, n=oneunit(tv[1] - tv[1]); kwargs...)

Shift vector `xv` by `n` with respect to time vector `tv`. Gaps in `tv` is allowed. Call `tlag` if `n` is positive and `tlead` if `n` is negative.
"""
function tshift(tv, xv, n=oneunit(tv[1] - tv[1]); kwargs...)
    if n > zero(n)
        return tlag(tv, xv, n; kwargs...)
    else
        return tlead(tv, xv, -n; kwargs...)
    end
end


"""
    panellag!(df, id, t, x, newx, n=oneunit(df[1, t] - df[1, t]); checksorted=true)

Within dataframe `df`, for each group indexed by `id`, lag column `x` by `n` periods with respect to the time column `t`, and store the lagged column under the name `newx`. Arguments `id`, `t`, `x`, and `newx` are all column indicies in `df`.

# Examples
```jldoctest
julia> using DataFrames;
julia> df = DataFrame(
    t = [1;2;3;4; 1;3;4; 1;4; 1], 
    id = [1;1;1;1; 2;2;2; 3;3; 4],
    x = [1;2;3;4; 5;6;7; 8;9; 10]
);
julia> panellag!(df, :id, :t, :x, :Lx)

10×4 DataFrame
 Row │ t      id     x      Lx      
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

See also `panellead!`, `panelshift!`.
"""
function panellag!(df, id, t, x, newx, n=oneunit(df[1, t] - df[1, t]); checksorted=true)
    return transform!(groupby(df, id), [t, x] => ((t, x) -> tlag(t, x, n; checksorted=checksorted)) => newx)
end

"""
    panellead!(df, id, t, x, newx, n=oneunit(df[1, t] - df[1, t]); checksorted=true)

Within dataframe `df`, for each group indexed by `id`, lead (forward) column `x` by `n` periods with respect to the time column `t` using `tlag`, and store the forwarded column under the name `newx`. Arguments `id`, `t`, `x`, and `newx` are all column indicies in `df`.

# Examples
```jldoctest
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
"""
function panellead!(df, id, t, x, newx, n=oneunit(df[1, t] - df[1, t]); checksorted=true)
    return transform!(groupby(df, id), [t, x] => ((t, x) -> tlead(t, x, n; checksorted=checksorted)) => newx)
end

"""
    panelshift!(df, id, t, x, newx, n=oneunit(df[1, t] - df[1, t]); checksorted=true)

Within dataframe `df`, for each group indexed by `id`, shift column `x` by `n` periods with respect to the time column `t` using `tlead`, and store the shifted column under the name `newx`. Arguments `id`, `t`, `x`, and `newx` are all column indicies in `df`.

Call `tlag` if `n` is positive and `tlead` if `n` is negative.

See also `panellead!`, `panellag!`.
"""
function panelshift!(df, id, t, x, newx, n=oneunit(df[1, t] - df[1, t]); kwargs...)
    return transform!(groupby(df, id), [t, x] => ((t, x) -> tshift(t, x, n; checksorted=checksorted)) => newx)
end

end # module
