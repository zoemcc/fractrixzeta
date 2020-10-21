abstract type AbstractLantern end
abstract type LossFunctionLantern end

abstract type AbstractConformalTransform end

abstract type AbstractGameState end
abstract type AbstractPlayerState end
abstract type AbstractPlayerStateHistory end
abstract type AbstractWorldState end

abstract type AbstractConfig end

abstract type AbstractInputHandler end
@enum PLAYERINTENT moveforward=1 movebackward=2 moveleft=3 moveright=4 zoomout=5 zoomin=6 rotateleft=7 rotateright=8 plantlantern=9 stoprenderloop=10

