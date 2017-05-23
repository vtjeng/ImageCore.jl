using ImageCore, Colors, FixedPointNumbers, OffsetArrays
using Base.Test

@testset "reinterpret" begin
    # Gray
    for sz in ((4,), (4,5))
        a = rand(Gray{N0f8}, sz)
        for T in (Gray{N0f8}, Gray{Float32}, Gray{Float64})
            b = @inferred(convert(Array{T}, a))
            rb = @inferred(reinterpret(eltype(T), b))
            if ImageCore.squeeze1
                @test isa(rb, Array{eltype(T),length(sz)})
                @test size(rb) == sz
            else
                @test isa(rb, Array{eltype(T),length(sz)+1})
                @test size(rb) == (1,sz...)
            end
            c = copy(rb)
            rc = @inferred(reinterpret(T, c))
            @test isa(rc, Array{T,length(sz)})
            @test size(rc) == sz
        end
    end
    for sz in ((4,), (4,5))
        # Bool/Gray{Bool}
        b = rand(Bool, sz)
        rb = @inferred(reinterpret(Gray{Bool}, b))
        @test isa(rb, Array{Gray{Bool}, length(sz)})
        @test size(rb) == sz
        c = copy(rb)
        rc = @inferred(reinterpret(Bool, c))
        @test isa(rc, Array{Bool,length(sz)})
        @test size(rc) == sz
    end
    for sz in ((4,), (4,5))
        b = Gray24.(reinterpret(N0f8, rand(UInt8, sz)))
        for T in (UInt32, RGB24)
            rb = @inferred(reinterpret(T, b))
            @test isa(rb, Array{T,length(sz)})
            @test size(rb) == sz
            c = copy(rb)
            rc = @inferred(reinterpret(Gray24, c))
            @test isa(rc, Array{Gray24,length(sz)})
            @test size(rc) == sz
        end
    end
    # TransparentGray
    a = rand(AGray{N0f8}, (4,5))
    for T in (AGray{N0f8}, GrayA{Float32}, AGray{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (2,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    # Color3
    a = rand(RGB{N0f8}, (4,5))
    for T in (RGB{N0f8}, HSV{Float32}, XYZ{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (3,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    for a in (rand(RGB{N0f8}, 4), rand(RGB{N0f8}, (4,5)))
        b = @inferred(reinterpret(HSV{Float32}, float32.(a)))
        @test isa(b, Array{HSV{Float32}})
        @test ndims(b) == ndims(a)
    end
    # Transparent color
    a = rand(ARGB{N0f8}, (4,5))
    for T in (ARGB{N0f8}, AHSV{Float32}, AXYZ{Float64})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (4,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    # RGB1/RGB4
    a = rand(RGB{N0f8}, (4,5))
    for T in (RGB1{N0f8},RGB4{Float32})
        b = @inferred(convert(Array{T}, a))
        rb = @inferred(reinterpret(eltype(T), b))
        @test isa(rb, Array{eltype(T),3})
        @test size(rb) == (4,4,5)
        c = copy(rb)
        rc = @inferred(reinterpret(T, c))
        @test isa(rc, Array{T,2})
        @test size(rc) == (4,5)
    end
    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    @test @inferred(reinterpret(N0f8, a)) == cat(3, [1 0; 0 1; 0 0], [0 1; 0 1; 1 1])
    b = convert(Array{BGR{N0f8}}, a)
    @test @inferred(reinterpret(N0f8, b)) == cat(3, [0 0; 0 1; 1 0], [1 1; 0 1; 0 1])
    # RGB24, ARGB32
    for sz in ((4,), (4,5))
        a = rand(UInt32, sz)
        for T in (RGB24, ARGB32)
            b = @inferred(reinterpret(T, a))
            @test isa(b, Array{T,length(sz)})
            @test size(b) == sz
            @test eltype(b) == T
            @test @inferred(reinterpret(UInt32, b)) == a
        end
    end

    # 1d
    a = RGB{Float64}[RGB(1,1,0)]
    af = @inferred(reinterpret(Float64, a))
    anew = @inferred(reinterpret(RGB, vec(af)))
    @test anew[1] == a[1]
    @test ndims(anew) == 1

    # #33 and its converse
    a = reinterpret(BGRA{N0f8}, [0xf0884422])
    @test isa(a, Vector) && a == [BGRA{N0f8}(0.533,0.267,0.133,0.941)]
    @test reinterpret(UInt32, a) == [0xf0884422]
    @test size(reinterpret(BGRA{N0f8}, rand(UInt32, 5, 5))) == (5,5)
    @test size(colorview(ARGB32, rand(BGRA{N0f8}, 5, 5))) == (5,5)
    a = reinterpret(BGRA{N0f8}, [0x22, 0x44, 0x88, 0xf0, 0x01, 0x02, 0x03, 0x04])
    @test a == [BGRA{N0f8}(0.533,0.267,0.133,0.941), BGRA{N0f8}(0.012, 0.008, 0.004, 0.016)]
    @test reinterpret(UInt8, a) == [0x22, 0x44, 0x88, 0xf0, 0x01, 0x02, 0x03, 0x04]
    @test colorview(ARGB32, a) == reinterpret(ARGB32, [0xf0884422,0x04030201])

    # indeterminate type tests
    a = Array{RGB{AbstractFloat}}(3)
    @test_throws ArgumentError reinterpret(Float64, a)
    Tu = TypeVar(:T)
    a = Array{RGB{Tu}}(3)
    @test_throws ErrorException reinterpret(Float64, a)

    # Invalid conversions
    a = rand(UInt8, 4,5)
    ret = @test_throws TypeError reinterpret(Gray, a)
    a = rand(Int8, 4,5)
    ret = @test_throws TypeError reinterpret(Gray, a)
end

@testset "convert" begin
    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    c = @inferred(convert(Array{BGR}, a))
    @test eltype(c) == BGR{N0f8}
    c = @inferred(convert(Array{BGR{Float32}}, a))
    @test eltype(c) == BGR{Float32}
    c = @inferred(convert(Array{Lab}, a))
    @test eltype(c) == Lab{Float32}
    for a in (rand(Float32, (4,5)),
              bitrand(4,5))
        b = @inferred(convert(Array{Gray}, a))
        @test eltype(b) == Gray{eltype(a)}
        b = @inferred(convert(Array{Gray{N0f8}}, a))
        @test eltype(b) == Gray{N0f8}
    end
end

@testset "eltype conversion" begin
    @test float32(Float64) == Float32
    @test float32(N0f8)      == Float32
    @test float64(RGB{N0f8}) == RGB{Float64}

    a = [RGB(1,0,0) RGB(0,0,1);
         RGB(0,1,0) RGB(1,1,1)]
    @test eltype(a) == RGB{N0f8}
    @test eltype(n0f8.(a))       == RGB{N0f8}
    @test eltype(n6f10.(a)) == RGB{N6f10}
    @test eltype(n4f12.(a)) == RGB{N4f12}
    @test eltype(n2f14.(a)) == RGB{N2f14}
    @test eltype(n0f16.(a)) == RGB{N0f16}
#    @test eltype(float16.(a)) == RGB{Float16}
    @test eltype(float32.(a)) == RGB{Float32}
    @test eltype(float64.(a)) == RGB{Float64}

    a = N0f8[0.1,0.2,0.3]
    @test eltype(a) == N0f8
    @test eltype(n0f8.(a))       == N0f8
    @test eltype(n6f10.(a)) == N6f10
    @test eltype(n4f12.(a)) == N4f12
    @test eltype(n2f14.(a)) == N2f14
    @test eltype(n0f16.(a)) == N0f16
#    @test eltype(float16.(a)) == Float16
    @test eltype(float32.(a)) == Float32
    @test eltype(float64.(a)) == Float64

    a = OffsetArray(N0f8[0.1,0.2,0.3], -1:1)
    @test eltype(a) == N0f8
    @test eltype(n0f8.(a))       == N0f8
    @test eltype(n6f10.(a)) == N6f10
    @test eltype(n4f12.(a)) == N4f12
    @test eltype(n2f14.(a)) == N2f14
    @test eltype(n0f16.(a)) == N0f16
#    @test eltype(float16.(a)) == Float16
    @test eltype(float32.(a)) == Float32
    @test eltype(float64.(a)) == Float64
    @test indices(float32.(a)) == (-1:1,)
end

nothing
