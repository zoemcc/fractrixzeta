using FileIO
using VideoIO
using StaticArrays
using CUDA
import Makie

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
    mandelimg = map(z->mandelbrot(z, numiters), complexrange)
    
    return xrange, yrange, mandelimg
end


function gpu_add1!(y, x)
    for i in 1:length(y)
        @inbounds y[i] += x[i]
    end
    return nothing
end


function examplesettings()
    centerx = -0.5609882
    centery = 0.6409865
    scalefactorstart = 0.0
    scalefactorend = 4.0
    height = 360
    numiters = 40
    fps = 20
    seconds = 10.0
    aspectratio = 16/9
    scene = Makie.Scene()
    xrange, yrange, mandelimg = rendermandelbrotimagecuda(centerx, centery, scalefactorstart, numiters, height, aspectratio) 
    image = Makie.image!(scene, xrange, yrange, mandelimg, show_axis=false)
    #image = rendermandelbrotimageanimation(image, centerx, centery, scalefactorstart, scalefactorend, numiters, fps, seconds, height, aspectratio)
    return centerx, centery, scalefactorstart, scalefactorend, height, numiters, fps, seconds, aspectratio, image
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
        sleep(1/fps)
    end
    return image
end


