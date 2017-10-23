{.experimental.}
import random
import os
import strutils, math, threadpool
import times

const POOLSIZE = 5
const NUM_CHARACTERS = 1000
const TARGET = @[0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9]

type
    Agent* = ref object
        data*: seq[int]
        fitness*: float

proc newAgent(): Agent =
    sleep(1000)
    result = Agent()
    result.fitness = -1.0
    result.data = newSeq[int](TARGET.len)
    for i in 0..<TARGET.len:
        result.data[i] = random(NUM_CHARACTERS)

method calcFitness(this: Agent) {.base.} =
    this.fitness = 0.0
    for i in 0..<TARGET.len:
        if this.data[i] == TARGET[i]:
            this.fitness += 1.0
    this.fitness *= this.fitness

proc main() =
    echo getClockStr()    
    
    var pool = newSeq[FlowVar[Agent]](POOLSIZE)
    parallel:
        for i in 0..<pool.len:
            pool[i] = spawn newAgent()
    for i in 0..<pool.len:
        let agent = (^pool[i])
        echo agent.fitness
    
    echo getClockStr()        

main()