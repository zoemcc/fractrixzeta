function mandelbrot(z::Complex{T}, numiters::Integer) where {T <: Real}
    z_i = copy(z)
    if abs(z) > 2
        return 0
    end
    for escapeiter in 1:numiters
        z_i = z_i * z_i + z
        if abs(z_i) > 2
            return escapeiter
        end
    end
    return numiters
end

function generateranges(numxrange)

    aspectratio = 16 / 9
    xrange = LinRange(-2.8, 1.6, numxrange)
    xrangeextent = xrange.stop - xrange.start
    yrangeextent = xrangeextent / aspectratio
    yrange = LinRange(-yrangeextent / 2, yrangeextent / 2, Integer(floor(numxrange / aspectratio)))

    return xrange, yrange
end

function generatezoomranges(centerx, centery, scalefactor, numyrange, aspectratio=16/9)
    expscale = 2 ^ -scalefactor
    yrangeextent = expscale
    xrangeextent = expscale * aspectratio
    numxrange = Int(floor(numyrange * aspectratio))
    xrange = LinRange(centerx - xrangeextent / 2, centerx + xrangeextent / 2, numxrange)
    yrange = LinRange(centery - yrangeextent / 2, centery + yrangeextent / 2, numyrange)
    return xrange, yrange
end

function plotmandelbulb(xrange, yrange, numiters::Integer, plot=true, showaxis=true)
    complexrange = [Complex{Float64}(x, y) for x in xrange, y in yrange]
    mandelbrotupto(z) = 1 - mandelbrot(z, numiters) / numiters
    mandelbrotimg = mandelbrotupto.(complexrange)

    if plot
        scene = Makie.image(xrange, yrange, mandelbrotimg, show_axis=showaxis, scale_plot=false)
        return mandelbrotimg, scene
    else
        return mandelbrotimg
    end

end

function rendermandelbulbpng(xrange, yrange, numiters::Integer, savename::AbstractString) #, plot=true, showaxis=true)
    mandelbrotimg = rendermandelbulbimg(xrange, yrange, numiters)
    save(savename, mandelbrotimg)
end

function rendermandelbulbimg(xrange, yrange, numiters::Integer) #, plot=true, showaxis=true)
    mandelbrotimg = zeros(UInt8, yrange.len, xrange.len)
    for (j, y) in enumerate(yrange), (i, x) in enumerate(xrange)
        mandelxy = 255 * (1 - mandelbrot(Complex{Float64}(x, y), numiters) / numiters)
        mandelbrotimg[j, i] = UInt8(floor(mandelxy))
    end
    return mandelbrotimg
end


function rendermandelbulbvideo(centerx::Number, centery::Number, scalefactorstart::Number,
     scalefactorend::Number, numiters::Integer, fps::Integer, seconds::Number, height::Integer, aspectratio::Number, savename::AbstractString)
    time = 0:1/fps:seconds
    numsteps = length(time)
    mandels = Array{Array{UInt8, 2}, 1}(undef, numsteps)
    for (i, t) in enumerate(time)
        scalefactor = (scalefactorend - scalefactorstart) * (t / seconds) + scalefactorstart 
        xrange, yrange = generatezoomranges(centerx, centery, scalefactor, height, aspectratio)
        mandels[i] = rendermandelbulbimg(xrange, yrange, numiters) 
    end
    props = [:priv_data => ("cruf"=>"22", "preset"=>"medium")]
    encodevideo(savename, mandels, framerate=fps, AVCodecContextProperties=props)

end


function rendermandelbrotimagecuda(centerx::Number, centery::Number, scalefactor::Number,
     numiters::Integer, height::Integer, aspectratio::Number)
    xrange, yrange = generatezoomranges(centerx, centery, scalefactor, height, aspectratio)
    complexrange = [Complex{Float64}(x, y) for x in xrange, y in yrange]
    mandelimg = map(z->mandelbrot(z, numiters) / numiters, complexrange)
    
    return xrange, yrange, mandelimg
end



function examplesettings()
    centerx = -0.5609882
    centery = 0.6409865
    centerx = 0.0
    centery = 0.0
    scalefactorstart = 0.0
    scalefactorend = 4.0
    height = 480
    #numiters = 200
    numiters = 250
    #numiters = 40
    fps = 10
    seconds = 10.0
    aspectratio = 16/9
    width = Int(floor(360 * aspectratio))
    #scene, layout = MakieLayout.layoutscene(1, 1, padding=100, show_axis=false)
    #ax = layout[1, 1] = MakieLayout.LAxis(scene, show_axis=false)

    #scene = Makie.Scene(raw = true, resolution = (width, height))
    scene = Makie.Scene()
    xrange, yrange, mandelimg = rendermandelbrotimagecuda(centerx, centery, scalefactorstart, numiters, height, aspectratio) 
    #image = Makie.image!(scene, xrange, yrange, CUDA.CuArray(mandelimg), show_axis=false)
    #layout[1, 1] = Makie.image!(scene, xrange, yrange, mandelimg, show_axis=false, padding=0)
    #image = Makie.image!(ax, xrange, yrange, mandelimg, show_axis=false)
    #u = Makie.Node(0.0)
    #mandelimgnode = Makie.lift(x->mandelimg, u)
    mandelimgcolor = [ColorTypes.RGBA(Float32(color), Float32(color), Float32(color)) for color in mandelimg]
    image = Makie.image!(scene, mandelimgcolor, show_axis=false)
    #image = rendermandelbrotimageanimation(image, centerx, centery, scalefactorstart, scalefactorend, numiters, fps, seconds, height, aspectratio)
    return centerx, centery, scalefactorstart, scalefactorend, height, numiters, fps, seconds, aspectratio, scene#, u, mandelimgnode, mandelimg
    # centerx, centery, scalefactorstart, scalefactorend, height, numiters, fps, seconds, aspectratio, image = examplesettings(); image
end

function rendermandelbrotimageanimation(image, centerx::Number, centery::Number, scalefactorstart::Number,
     scalefactorend::Number, numiters::Integer, fps::Integer, seconds::Number, height::Integer, aspectratio::Number)
    time = 0:1/fps:seconds
    numsteps = length(time)
    for (i, t) in enumerate(time)
        scalefactor = (scalefactorend - scalefactorstart) * (t / seconds) + scalefactorstart 
        xrange, yrange, mandelimg = rendermandelbrotimagecuda(centerx, centery, scalefactor, numiters, height, aspectratio) 
        image.plots[1][:image][] = mandelimg
        #Makie.update!(image)
        sleep(0.0001)
    end
    return image
end

# includet("mandelbrot.jl"); centerx, centery, scalefactorstart, scalefactorend, height, numiters, fps, seconds, aspectratio, image = examplesettings(); image
# includet("mandelbrot.jl"); @time rendermandelbrotimageanimation2(image, centerx, centery, scalefactorstart, scalefactorend, numiters, fps, seconds, height, aspectratio, "")
function rendermandelbrotimageanimation2(image, centerx::Float64, centery::Float64, scalefactorstart::Number,
     scalefactorend::Number, numiters::Integer, fps::Integer, seconds::Number, height::Integer, aspectratio::Number, savename::AbstractString)
    #time = 0:1/fps:seconds
    #numsteps = length(time)
    width = Int(floor(aspectratio * height))

    escape = CUDA.fill(0.0, width, height)
    escape_color = CUDA.fill(ColorTypes.RGBA{Float32}(0.0, 0.0, 0.0), width, height)
    escape_cpu = zeros(Float64, width, height)
    escape_cpu_color = [ColorTypes.RGBA(Float32(0.5), Float32(0.5), Float32(0.5)) for x in 1:width, y in 1:height]
    grayscalecolors = [ColorTypes.RGBA(i/255, i/255, i/255) for i in 0:255]
    for (l, z) in enumerate(escape_cpu)
        escape_cpu_color[l] = grayscalecolors[100]
    end
    #@show typeof(escape_cpu)

    numtype = Float64
    local scalefactor = numtype(copy(scalefactorstart))
    local centerxlocal = numtype(copy(centerx))
    local centerylocal = numtype(copy(centery))
    local rotation = numtype(0.0)

    local wdown = false
    local adown = false
    local sdown = false
    local ddown = false
    local jdown = false
    local kdown = false
    local udown = false
    local idown = false

    local endscene = false

    movementscale = numtype(0.2)
    zoomscale = numtype(1.0)
    rotscale = numtype(1.0)

    Makie.lift(image.events.keyboardbuttons) do but
        #@show but

        wdown = Makie.Keyboard.w in but
        adown = Makie.Keyboard.a in but
        sdown = Makie.Keyboard.s in but
        ddown = Makie.Keyboard.d in but

        jdown = Makie.Keyboard.j in but
        kdown = Makie.Keyboard.k in but

        udown = Makie.Keyboard.u in but
        idown = Makie.Keyboard.i in but

        endscene = Makie.Keyboard.left_control in but

        nothing
    end


    N = width * height
    #numblocks = ceil(Int, N/32)
    numthreads = (16, 16)
    numblocks = ceil(Int, width / numthreads[1]), ceil(Int, height / numthreads[2])
    #@show numblocks
    i = 0
    listener = image.plots[1][:image].listeners[1]
    makimg = image.plots[1][:image]
    a = Complex{numtype}(1., 0.)
    b = Complex{numtype}(0., 0.)
    c = Complex{numtype}(0., 0.)
    d = Complex{numtype}(1., 0.)

    mobiusparams = [a, b, c, d]

    z1 = Complex{numtype}(-1.4, 0.)
    z2 = Complex{numtype}(1., -1.)
    lr = 0.02

    lambdaangle = numtype(0.5)
    adisk = Complex{numtype}(numtype(0.2), numtype(0.3))
    lambdaangle, adisk = randomdiskmobius()

    lambdaangletarget, adisktarget = randomdiskmobius()

    #a, b, c, d = diskmobius(lambdaangle, adisk)

    starttime = time()
    local prevtime = starttime
    local mobiuswalktime = prevtime

    l = 0
    while !endscene
    #for k in 1:1
    #Makie.record(image, savename, enumerate(time); framerate=60) do (i, t)
        CUDA.fill!(escape, 0.0)


        curtime = time()
        deltatime = curtime - prevtime
        curtimeperframe = (curtime - starttime) / i
        #@show curtimeperframe
        curfps = 1 / curtimeperframe
        if i % 20 == 0
            @show curfps
        end

        expscale = numtype(2.0 ^ -scalefactor)
        yrangeextent = numtype(expscale)
        xrangeextent = numtype(expscale * aspectratio)
        xstart = numtype(-xrangeextent / 2)
        ystart = numtype(-yrangeextent / 2)

        cosrot = numtype(cos(rotation))
        sinrot = numtype(sin(rotation))

        if wdown
            centerxlocal += -sinrot * movementscale * expscale * deltatime
            centerylocal += cosrot * movementscale * expscale * deltatime
            #@show centerxlocal
            #@show centerylocal
        end
        if adown
            centerxlocal -= cosrot * movementscale * expscale * deltatime
            centerylocal -= sinrot * movementscale * expscale * deltatime
            #@show centerxlocal
            #@show centerylocal
        end
        if sdown
            centerxlocal -= -sinrot * movementscale * expscale * deltatime
            centerylocal -= cosrot * movementscale * expscale * deltatime
            #@show centerxlocal
            #@show centerylocal
        end
        if ddown
            centerxlocal += cosrot * movementscale * expscale * deltatime
            centerylocal += sinrot * movementscale * expscale * deltatime
            #@show centerxlocal
            #@show centerylocal
        end

        # note: scale factor for Float32 is approximately capped at 32
        if jdown
            scalefactor -= zoomscale * deltatime
            expscale = numtype(2.0 ^ -scalefactor)
            yrangeextent = numtype(expscale)
            xrangeextent = numtype(expscale * aspectratio)
            xstart = numtype(-xrangeextent / 2)
            ystart = numtype(-yrangeextent / 2)
            #@show scalefactor
        end
        if kdown
            scalefactor += zoomscale * deltatime
            expscale = numtype(2.0 ^ -scalefactor)
            yrangeextent = numtype(expscale)
            xrangeextent = numtype(expscale * aspectratio)
            xstart = numtype(-xrangeextent / 2)
            ystart = numtype(-yrangeextent / 2)
            #@show scalefactor
        end

        if udown
            rotation -= rotscale * deltatime
            cosrot = numtype(cos(rotation))
            sinrot = numtype(sin(rotation))
            #@show rotation
        end
        if idown
            rotation += rotscale * deltatime
            cosrot = numtype(cos(rotation))
            sinrot = numtype(sin(rotation))
            #@show rotation
        end

        if curtime - mobiuswalktime > 3
            lambdaangletarget, adisktarget = randomdiskmobius()
            mobiuswalktime = curtime
        end

        lambdaangle += (lambdaangletarget - lambdaangle) * deltatime
        adisk += (adisktarget - adisk) * deltatime
        #a, b, c, d = diskmobius(lambdaangle, adisk)

        distfunc = mobiusparams -> complexdist(mobiustransform(z1, mobiusparams...), z2)
        distparams = distfunc(mobiusparams)
        gradmobius = gradient(distfunc, mobiusparams)[1]
        mobiusparams .-= gradmobius .* lr .* distparams
        if distparams < 1e-3 || l > 100
            z2 = Complex{numtype}(randn(), randn())
            l = 0
        end
        l += 1
        if i % 5 == 0
            @show distfunc(mobiusparams)
            @show z2
            #@show mobiusparams
            #@show gradmobius
        end
        
        #@show "cuda"
        #@time CUDA.@sync begin
        CUDA.@sync begin
            #@cuda threads=numthreads blocks=numblocks mandelbrotandregiongpu!(escape, centerxlocal, xstart, xrangeextent, centerylocal, ystart, yrangeextent, numiters, height, width, cosrot, sinrot, a, b, c, d)
            @cuda threads=numthreads blocks=numblocks mandelbrotandregiongpu!(escape_color, centerxlocal, xstart, xrangeextent, centerylocal, ystart, yrangeextent, numiters, height, width, cosrot, sinrot, mobiusparams...)
        end

        #@show "copy"
        #@time CUDA.copyto!(escape_cpu, escape)
        CUDA.copyto!(escape_cpu_color, escape_color)

        #@show "copytocolor"
        #for (l, z) in enumerate(escape_cpu)
            #escape_cpu_color[l] = ColorTypes.RGBA{Float32}(Float32(z), Float32(z), Float32(z))
        #end

        #@show "imageplotcopy"
        makimg[] = escape_cpu_color

        i += 1
        sleep(0.0001)
        prevtime = curtime
        #end
    end
    #@show length(time)
    #return escape
    return nothing
end

#function mandelbrotandregiongpu!(escape, centerx, xstart, xrangeextent, centery, ystart, yrangeextent, numiters, height, width, cosrot, sinrot, a, b, c, d)
function mandelbrotandregiongpu!(escape_color, centerx::N, xstart::N, xrangeextent::N, centery::N, ystart::N, yrangeextent::N, 
    numiters, height, width, cosrot::N, sinrot::N, a::Complex{N}, b::Complex{N}, c::Complex{N}, d::Complex{N}) where {N <: Real}
    indexx = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    indexy = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    stridex = blockDim().x * gridDim().x
    stridey = blockDim().y * gridDim().y
    #@cuprintln("thread $indexx, $indexy, stride $stridex, $stridey, weight $width $height")
    for i in indexx:stridex:width, j in indexy:stridey:height
        prex_ij = (i - 1) / (width - 1) * xrangeextent + xstart
        prey_ij = (j - 1) / (height - 1) * yrangeextent + ystart
        z_ij = Complex{N}(cosrot * prex_ij - sinrot * prey_ij + centerx, sinrot * prex_ij + cosrot * prey_ij + centery)
        z_ij_mobius = mobiustransform(z_ij, a, b, c, d)
        escape_ij = mandelbrot(z_ij_mobius, numiters) / numiters
        escape_ij_f32 = Float32(escape_ij)
        @inbounds escape_color[i, j] = ColorTypes.RGBA{Float32}(escape_ij_f32, escape_ij_f32, escape_ij_f32)
    end
    return
end

function mobiustransform(z::Complex{N}, a::Complex{N}, b::Complex{N}, c::Complex{N}, d::Complex{N})::Complex{N} where {N <: Real}
    return (z * a + b) / (z * c + d)
end


function complexdist(z1::Complex{N}, z2::Complex{N})::N where {N <: Real}
    return abs(z1 - z2)
end

function diskmobius(lambdaangle::N, a::Complex{N}) where {N <: Real}
    # maps the unit disk to itself
    # example 4 in section 3.4 in Complex Variables 2nd Ed by Stephen Fisher book
    # f(z) = lambda * (a - z) / (1 - āz)
    lambda = Complex{N}(cos(lambdaangle), sin(lambdaangle))
    moba = -lambda
    mobb = lambda * a
    mobc = -conj(a)
    mobd = Complex{N}(1, 0)
    return moba, mobb, mobc, mobd
end

function randomdiskmobius()
    lambdaangle = rand(Float64) * τ
    aangle = rand(Float64) * τ
    aradius = rand(Float64)
    a = Complex{Float64}(aradius * cos(aangle), aradius * sin(aangle))
    return lambdaangle, a
end


function gpu_add3!(y, x)
    index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = blockDim().x * gridDim().x
    for i in index:stride:length(y)
        @inbounds y[i] += x[i]
    end
    return nothing
end

function cudastuff()
    N = 1024
    x = CUDA.fill(1., N)
    y = CUDA.fill(2., N)
    numblocks = ceil(Int, N/256)
    @cuda threads=256 blocks=numblocks gpu_add3!(y, x)
    @show y
end

function bench_gpu3!(y, x)
    numblocks = ceil(Int, length(y)/256)
    CUDA.@sync begin
        @cuda threads=256 blocks=numblocks gpu_add3!(y, x)
    end
end

function gpu_mandel!(escape, z, numiters)
    index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = blockDim().x * gridDim().x
    for i in index:stride:length(z)
        @inbounds escape[i] += mandelbrot(z[i], numiters)
    end
    return
end

function cudastuffmandel()
    centerx = -0.5609882
    centery = 0.6409865
    scalefactor = 1.0
    height = 360
    numiters = 200
    aspectratio = 16/9
    width = Int(floor(aspectratio * height))

    xrange, yrange = generatezoomranges(centerx, centery, scalefactor, height, aspectratio)
    z = CUDA.CuArray([Complex{Float64}(x, y) for x in xrange, y in yrange])
    escape = CUDA.fill(0., width, height)

    N = width * height
    numblocks = ceil(Int, N/256)
    #@cuda threads=256 blocks=numblocks gpu_mandel!(escape, z, numiters)
    #@show escape
    function bench_mandelgpu!(escapecur, zcur)
        CUDA.@sync begin
            @cuda threads=256 blocks=numblocks gpu_mandel!(escapecur, zcur, numiters)
        end
    end
    return escape, z, bench_mandelgpu!

end

