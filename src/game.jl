
struct Game{GameState <: AbstractGameState, Renderer <: AbstractRenderer, InputHandler <: AbstractInputHandler, Config <: AbstractConfig}
    gamestate::GameState
    renderer::Renderer
    inputhandler::InputHandler
    config::Config
end

function initgame()
    # do basic shit first
    gamestate = init_game_state()
    renderer = init_renderer()
    inputhandler = NoInputHandler()
    config = NoConfig()
    Game(gamestate, renderer, inputhandler, config)
end

