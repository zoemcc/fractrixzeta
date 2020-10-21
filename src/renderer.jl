abstract type AbstractRenderer end


struct MakieRenderer <: AbstractRenderer
    scene::AbstractPlotting.Scene
    image::Observables.Observable{Array{ColorTypes.RGBA{Float32}, 2}}
    cudaimage::CuArray{ColorTypes.RGBA{Float32}, 2}
    numiters::Int64 # Should this be here? Where would be better?
    aspectratio::Float64
    height::Int64
    width::Int64
end

scene(renderer::MakieRenderer) = renderer.scene

function init_renderer()
    scene = Makie.Scene()
    height = 360
    aspectratio = 16/9
    width = Int(floor(height * aspectratio))
    numiters = 250
    xrange, yrange, mandelimg = rendermandelbrotimagecuda(0., 0., 0., numiters, height, aspectratio) 
    mandelimgcolor = [ColorTypes.RGBA(Float32(color), Float32(color), Float32(color)) for color in mandelimg]
    cudaimage = CUDA.CuArray(mandelimgcolor)
    Makie.image!(scene, mandelimgcolor, show_axis=false)
    display(scene)
    image = scene.plots[1][:image]
    MakieRenderer(scene, image, cudaimage, numiters, aspectratio, height, width)
end

function render_game(renderer::MakieRenderer, gamestate::AbstractGameState)
    numtype = Float64
    # First gather the parameters
    # Renderer parameters
    numiters = renderer.numiters
    outimage = renderer.image
    cudaimage = renderer.cudaimage
    aspectratio = renderer.aspectratio
    height = renderer.height
    width = renderer.width

    numthreads = (16, 16)
    numblocks = ceil(Int, width / numthreads[1]), ceil(Int, height / numthreads[2])

    # GameState parameters
    center = position(player(gamestate))
    centerx, centery = real(center), imag(center) #.+ 0.4 .* randn.()
    #rotationfactor, scalefactor = rotation(player(gamestate)) + 0.5 * randn(), scale(player(gamestate)) + 0.5 * randn()
    rotationfactor, scalefactor = rotation(player(gamestate)), scale(player(gamestate))

    expscale = numtype(2 ^ -scalefactor)
    yrangeextent = numtype(expscale)
    xrangeextent = numtype(expscale * aspectratio)
    xstart = numtype(-xrangeextent / 2)
    ystart = numtype(-yrangeextent / 2)
    cosrot = numtype(cos(rotationfactor))
    sinrot = numtype(sin(rotationfactor))

    mobius = current_transform(world(gamestate))
    a, b, c, d = mobius.a, mobius.b, mobius.c, mobius.d

    # then call 
    CUDA.@sync begin
        @cuda threads=numthreads blocks=numblocks mandelbrotandregiongpu!(cudaimage,
            centerx, xstart, xrangeextent, centery, ystart, yrangeextent,
            numiters, height, width, cosrot, sinrot, a, b, c, d)
    end

    CUDA.copyto!(outimage[], cudaimage)
    Observables.notify!(outimage)
    sleep(0.0001)
    outimage[]
end

