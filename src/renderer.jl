abstract type AbstractRenderer end


struct MakieRenderer <: AbstractRenderer
    scene::AbstractPlotting.Scene
    image::Observables.Observable{Array{ColorTypes.RGBA{Float32}, 2}}
    cudaimage::CuArray{ColorTypes.RGBA{Float32}, 2}
    numiters::Int64 # Should this be here? Where would be better?
    aspectratio::Float64
    height::Int64
    width::Int64
    #camera::AbstractPlotting::Camera2D
end

scene(renderer::MakieRenderer) = renderer.scene

function init_renderer()
    #scene = Makie.Scene()
    height = 360
    aspectratio = 16/9
    width = Int(floor(height * aspectratio))
    numiters = 250
    xrange, yrange, mandelimg = rendermandelbrotimagecuda(0., 0., 0., numiters, height, aspectratio) 
    mandelimgcolor = [ColorTypes.RGBA(Float32(color), Float32(color), Float32(color)) for color in mandelimg]
    cudaimage = CUDA.CuArray(mandelimgcolor)

    #cam = 

    #Node = Observables.Node
    #camera = AbstractPlotting.Camera2D(AbstractPlotting.Node(FRect(0,0,width,height)), AbstractPlotting.Node(0.0f0), 
        #AbstractPlotting.Node(nothing), AbstractPlotting.Node(nothing), AbstractPlotting.Node(0.0f0), 
        #AbstractPlotting.Node(Vec{2, Int}(width, height)), AbstractPlotting.Node(false))
    theme = AbstractPlotting.Attributes(show_axis=false, raw=false, scale_plot=true, 
                        padding=Point3(0.0f0, 0.0f0, 0.0f0), 
                        align= (:middle, :middle),
                        #resolution=(640, 360), #limits=FRect(0, 0, 640, 360),
                        panbutton=nothing, update_limits=true)
    AbstractPlotting.set_theme!(theme)

    scene = Makie.image(mandelimgcolor)
    #cam = AbstractPlotting.cam2d!(scene; padding=0.000, area=AbstractPlotting.Node(FRect(0,0,width,height)))
    #cam = AbstractPlotting.cam2d!(scene; padding=0.000, area=AbstractPlotting.Node(FRect(0,0,width,height)))
    #AbstractPlotting.update_cam!(scene, cam)
    #AbstractPlotting.update!(scene)
    display(scene)
    #AbstractPlotting.update_cam!(scene)
    #AbstractPlotting.update!(scene)
    #display(scene)
    image = scene.plots[1][:image]
    Observables.notify!(image)
    #AbstractPlotting.update_cam!(scene, camera)
    cam = AbstractPlotting.cam2d!(scene; padding=0.000, area=AbstractPlotting.Node(FRect(0,0,width,height)), 
        panbutton=nothing, update_limits=true)
    AbstractPlotting.update_cam!(scene, cam)
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

    #mobius = current_transform(world(gamestate))
    conformal = current_transform(world(gamestate))
    #a, b, c, d = mobius.a, mobius.b, mobius.c, mobius.d

    # then call 
    CUDA.@sync begin
        #@cuda threads=numthreads blocks=numblocks mandelbrotandregiongpu!(cudaimage,
            #centerx, xstart, xrangeextent, centery, ystart, yrangeextent,
            #numiters, height, width, cosrot, sinrot, a, b, c, d)
        @cuda threads=numthreads blocks=numblocks mandelbrotandregiongpurational!(cudaimage,
            centerx, xstart, xrangeextent, centery, ystart, yrangeextent,
            numiters, height, width, cosrot, sinrot, conformal)
    end

    CUDA.copyto!(outimage[], cudaimage)
    Observables.notify!(outimage)
    #AbstractPlotting.update_cam!(renderer.scene)
    sleep(0.0001)
    outimage[]
end

