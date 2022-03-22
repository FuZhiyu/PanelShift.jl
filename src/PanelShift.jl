module PanelShift

using DataFrames
using ArgCheck
export tlag!, tlag, tlead!, tlead, tshift
export panellag!, panellead!, panelshift!

function tlag!(nxv, tv, xv, n = oneunit(tv[1] - tv[1]); checksorted = true)
    @argcheck (n > zero(n)) "n has to be strictly positive."
    if checksorted    
        @argcheck issorted(tv , lt = <=) "The time vector is not strictly increasing!"
    end
    T = length(tv)
    @argcheck length(xv) == T "xv and tv have different lenths!"
    local j = 0
    for i in 1:T
        lagt = tv[i] - n
        # find the largest t that is no greater than lagt
        while true
            if tv[j+1] <= lagt
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

function tlead!(nxv, tv, xv, n = oneunit(tv[1] - tv[1]); checksorted = true)
    @argcheck (n > zero(n)) "n has to be strictly positive."
    if checksorted    
        @argcheck issorted(tv , lt = <=) "The time vector is not strictly increasing!"
    end
    T = length(tv)
    @argcheck length(xv) == T "xv and tv have different lenths!"
    local j = T+1
    for i in T:-1:1
        leadt = tv[i] + n
        # find the smallest t that is no smaller than leadt
        while true
            if tv[j-1] >= leadt
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

using DataFrames
function tlag(tv, xv, n = oneunit(tv[1] - tv[1]); checksorted = true)
    nxv = allowmissing(similar(xv))
    return tlag!(nxv, tv, xv, n, checksorted = checksorted)
end

function tlead(tv, xv, n = oneunit(tv[1] - tv[1]); checksorted = true)
    nxv = allowmissing(similar(xv))
    return tlead!(nxv, tv, xv, n, checksorted = checksorted)
end

function tshift(tv, xv, n = oneunit(tv[1] - tv[1]); kwargs...)
    if n > zero(n)
        return tlag(tv, xv, n; kwargs...)
    else
        return tlead(tv, xv, -n; kwargs...)
    end
end

function panellag!(df, id, t, x, newx, n = oneunit(df[1, t]-df[1, t]); checksorted = true)
    @argcheck (n > zero(n)) "n has to be strictly positive."
    transform!(groupby(df, id), [t, x] => ((t, x)->tlag(t, x, n; checksorted=checksorted)) => newx)
end

function panellead!(df, id, t, x, newx, n = oneunit(df[1, t]-df[1, t]); checksorted = true)
    @argcheck (n > zero(n)) "n has to be strictly positive."
    transform!(groupby(df, id), [t, x] => ((t, x)->tlag(t, x, n; checksorted=checksorted)) => newx)
end

function panelshift!(df, id, t, x, newx, n = oneunit(df[1, t]-df[1, t]); kwargs...)
    transform!(groupby(df, id), [t, x] => ((t, x)->tshift(t, x, n; checksorted=checksorted)) => newx)
end

end # module
