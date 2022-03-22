
using Test
using PanelShift
using Dates

equalormi(x, y) = all([(ismissing(i) && ismissing(j)) || i == j for (i,j) in zip(x,y)])

@test equalormi(tlag([1;2;3], [4;5;6], 1), [missing;4;5])
@test equalormi(tlead([1;2;3], [4;5;6], 1), [5; 6; missing])

@test equalormi(tlag([1;2;3], [4;5;6], 2), [missing;missing;4])
@test equalormi(tlead([1;2;3], [4;5;6], 2), [6; missing; missing])

# unit-length vector
@test equalormi(tlag([1], [1]), [missing;])
@test equalormi(tlead([1], [1]), [missing;])

@test equalormi(tlag([1;3;5;6;7], [1;2;3;4;5], 2), [missing; 1; 2; missing; 3])
@test equalormi(tlag(float.([1;3;5;6;7]), [1;2;3;4;5], 2), [missing; 1; 2; missing; 3])

# non-numeric x and unequal gaps
@test equalormi(tlag([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 1), [missing; :apple; missing; missing; missing])
@test equalormi(tlag([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 2), [missing; missing; :orange; missing; missing])
@test equalormi(tlag([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 3), [missing; missing; :apple; :banana; missing])
@test equalormi(tlag([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 4), [missing; missing; missing; missing; :pineapple])
@test equalormi(tlead([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 4), [missing; missing; missing; :strawberry; missing])


# indexed by dates 
@test equalormi(tlag([Date(2000,1,1), Date(2000, 1,2), Date(2000,1, 4)], [1,2,3], Day(1)), [missing; 1; missing])
@test equalormi(tlag([Date(2000,1,1), Date(2000, 1,2), Date(2000,1, 4)], [1,2,3], Day(2)), [missing; missing; 2])


# test shift
@test equalormi(tshift([1;2;3], [1;2;3], -1), tlead([1;2;3], [1;2;3], 1))
@test equalormi(tshift([1;2;3], [1;2;3], 1), tlag([1;2;3], [1;2;3], 1))

# safeguards
@test_throws ArgumentError tlag([1;2;2], [1,2,3])
@test_throws ArgumentError tlag([1;2;], [1,2,3])
@test_throws ArgumentError tlag([1;2;3], [1,2,3], 0)

using DataFrames

df = DataFrame(
    t = [1;2;3;4; 1;3;4; 1;4; 1], 
    id = [1;1;1;1; 2;2;2; 3;3; 4],
    x = [1;2;3;4; 5;6;7; 8;9; 10]
)

panellag!(df, :id, :t, :x, :Lx)
@test equalormi(df.Lx, [missing; 1; 2; 3; missing; missing; 6; missing; missing; missing])
