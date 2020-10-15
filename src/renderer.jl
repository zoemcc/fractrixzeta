abstract type AbstractRenderer end


struct MakieRenderer <: AbstractRenderer
    scene::AbstractPlotting.Scene
    image::Observables.Observable{Array{ColorTypes.RGBA{Float32}, 2}}
end

function init_renderer()
    scene = Makie.Scene()
    height = 480
    aspectratio = 16/9
    width = Int(floor(360 * aspectratio))
    xrange, yrange, mandelimg = rendermandelbrotimagecuda(0., 0., 0., 250, height, aspectratio) 
    mandelimgcolor = [ColorTypes.RGBA(Float32(color), Float32(color), Float32(color)) for color in mandelimg]
    Makie.image!(scene, mandelimgcolor, show_axis=false)
    display(scene)
    image = scene.plots[1][:image]
    MakieRenderer(scene, image)
end

#function update_image(renderer::MakieRenderer)
    #renderer.image[] = image
    #image
#end


function render_game(renderer::AbstractRenderer, gamestate::AbstractGameState)
    # first gather the parameters

    # then call 

end

