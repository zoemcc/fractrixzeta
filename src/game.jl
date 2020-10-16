
struct Game{GameState <: AbstractGameState, Renderer <: AbstractRenderer, InputHandler <: AbstractInputHandler, Config <: AbstractConfig}
    gamestate::GameState
    renderer::Renderer
    inputhandler::InputHandler
    config::Config
end

function init_game()
    # do basic shit first
    config = NoConfig()
    gamestate = init_game_state()
    renderer = init_renderer()
    inputhandler = NoInputHandler()
    Game(gamestate, renderer, inputhandler, config)
end

function run_game(game::Game)
    newlantern = DistanceGoalLantern(Complex(-1.4, 0), Complex(0.7, 0.7))
    for i in 1:200
        render_game(game.renderer, game.gamestate) 
        new_transform = evolvetransform(newlantern, game.gamestate.worldstate.current_transform)
    end
end

