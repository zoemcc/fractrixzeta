using GLMakie
using ColorTypes

scene = GLMakie.Scene()
width = 640
height = 360
#im = convert.(ColorTypes.RGBA, rand(Float32, width, height))
@time img = [ColorTypes.RGBA(rand(Float32, 3)...) for x in 1:width, y in 1:height]
glim = GLMakie.image!(scene, img, show_axis=false)
makimg = scene.plots[1]

@time makimg[:image][] = img
@run scene.plots[1][:image][] = rand(Float32, width, height)
#glim = scene.plots[1]
