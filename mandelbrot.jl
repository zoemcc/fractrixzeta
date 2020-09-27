using FileIO
using VideoIO
using StaticArrays
using CUDA
import Makie
import AbstractPlotting.MakieLayout

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
    scalefactorstart = 0.0
    scalefactorend = 4.0
    height = 360
    #numiters = 200
    numiters = 450
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
    image = Makie.image!(scene, xrange, yrange, mandelimg, show_axis=false)
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

function rendermandelbrotimageanimation2(image, centerx::Float64, centery::Float64, scalefactorstart::Number,
     scalefactorend::Number, numiters::Integer, fps::Integer, seconds::Number, height::Integer, aspectratio::Number, savename::AbstractString)
    time = 0:1/fps:seconds
    numsteps = length(time)
    width = Int(floor(aspectratio * height))

    escape = CUDA.fill(0.0, width, height)
    escape_cpu = zeros(Float64, width, height)
    #@show typeof(escape_cpu)

    local scalefactor = Float64(copy(scalefactorstart))
    local centerxlocal = Float64(copy(centerx))
    local centerylocal = Float64(copy(centery))

    local endscene = false

    Makie.lift(image.events.keyboardbuttons) do but
        @show but
        expscale = Float64(2.0 ^ -scalefactor)
        local modified = false
        movementscale = 0.01
        zoomscale = 0.05
        @show typeof(but)
        #@show Makie.Keyboard.w in but
        if Makie.Keyboard.w in but
            centerylocal += movementscale * expscale
            @show centerylocal
            modified = true
        end
        if Makie.Keyboard.a in but
            centerxlocal -= movementscale * expscale * aspectratio
            @show centerxlocal
            modified = true
        end
        if Makie.Keyboard.s in but
            centerylocal -= movementscale * expscale
            @show centerxlocal
            modified = true
        end
        if Makie.Keyboard.d in but
            centerxlocal += movementscale * expscale * aspectratio
            @show centerxlocal
            modified = true
        end

        #if Makie.ispressed(but, Makie.Keyboard.j) 
        if Makie.Keyboard.j in but
            scalefactor -= zoomscale
            @show scalefactor
            modified = true
        end
        if Makie.Keyboard.k in but
            scalefactor += zoomscale
            @show scalefactor
            modified = true
        end

        if Makie.Keyboard.left_control in but
            endscene = true
        end
        modified

    end


    N = width * height
    #numblocks = ceil(Int, N/32)
    numthreads = (16, 16)
    numblocks = ceil(Int, width / numthreads[1]), ceil(Int, height / numthreads[2])
    #@show numblocks
    i = 0
    while !endscene
    #while false
        #for (i, t) in enumerate([time; reverse(time)])
        #Makie.record(image, savename, enumerate(time); framerate=60) do (i, t)
        CUDA.fill!(escape, 0.0)
        #scalefactor = (scalefactorend - scalefactorstart) * (t / seconds) + scalefactorstart 

        expscale = Float64(2.0 ^ -scalefactor)
        yrangeextent = expscale
        xrangeextent = expscale * aspectratio
        xstart = centerxlocal - xrangeextent / 2
        ystart = centerylocal - yrangeextent / 2
        
        CUDA.@sync begin
            @cuda threads=numthreads blocks=numblocks mandelbrotandregiongpu!(escape, xstart, xrangeextent, ystart, yrangeextent, numiters, height, width, aspectratio)
        end
        CUDA.copyto!(escape_cpu, escape)
        #CUDA.copyto!(image.plots[1][:image][], escape)
        #@show image.plots[1][:image][][200, 200]
        image.plots[1][:image][] = escape_cpu
        #@show typeof(image.plots[1].attributes)
        #u[] = sin(Float64(i))
        #image.plots[1][:image][] = escape_cpu
        #image.plots[1][:image][] = image.plots[1][:image][]
        #image.plots[1][:visible][] = true
        #@show image.plots[1][:image][][200, 200]
        #Makie.update!(image)
        #Makie.update!(image)

        #@show escape
        i += 1
        sleep(0.0001)
        #end
    end
    @show length(time)
    #return escape
    return nothing
end

function mandelbrotandregiongpu!(escape, xstart, xrangeextent, ystart, yrangeextent, numiters, height, width, aspectratio)
    indexx = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    indexy = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    stridex = blockDim().x * gridDim().x
    stridey = blockDim().y * gridDim().y
    #@cuprintln("thread $indexx, $indexy, block $stridex, $stridey")
    #@cuprintln("thread $indexx, $indexy")
    for i in indexx:stridex:width, j in indexy:stridey:height
        x_ij = (i - 1) / (width - 1) * xrangeextent + xstart
        y_ij = (j - 1) / (height - 1) * yrangeextent + ystart
        z_ij = ComplexF64(x_ij, y_ij)
        @inbounds escape[i, j] += mandelbrot(z_ij, numiters) / numiters
    end
    return
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

