import ClobberingReload

a = ClobberingReload.parse_file("docstring.jl")[1] # TODO: see comment in that file
@test TraceCalls.strip_docstring(a).head == :function

################################################################################
# RevertibleCodeUpdate

# That's a hacky way of reusing the test file in ClobberingReload
push!(LOAD_PATH, joinpath(@__DIR__, "..", "..", "ClobberingReload", "test"))
using AA

include("incl.jl")

counter = fill(0)
function add_counter(fdef)
    di = ClobberingReload.splitdef(fdef)
    di[:body] = quote $counter .+= 1; $(di[:body]) end
    ClobberingReload.combinedef(di)
end
upd_high = update_code_revertible(AA.high) do code
    add_counter(code)
end
upd_module = update_code_revertible(AA) do code
    if TraceCalls.is_function_definition(code) add_counter(code) end
end
upd_include = update_code_revertible("incl.jl") do code
    if TraceCalls.is_function_definition(code) add_counter(code) end
end
@test AA.high(1) == 10
@test counter[] == 0
upd_high() do
    @test AA.high(1) == 10
    @test AA.high(1.0) == 2
end
@test AA.high(1) == 10
@test AA.bar(1.0) == 2
@test counter[] == 2 # only the two calls within `upd` increase the counter
upd_module() do
    @test AA.high(1) == 10
    @test AA.high(1.0) == 2
end
@test counter[] == 5 # three calls, since `bar` also becomes counting
upd_include() do
    @test apple() == :orange
end
apple()
@test counter[] == 6
    
################################################################################

@test length(source(ClobberingReload.creload)) == 2
source(Base.which) # check that it works with Base
source(Base.vcat)  # nested where (as of July '17)
