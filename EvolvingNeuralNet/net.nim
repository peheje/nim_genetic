import layer
import neuron
import datasets
import helpers
import algorithm
import random
import math

type
    Net* = ref object
        layers*: seq[Layer]
        fitness*: float
        correct*, weights*: int

proc newNet*(setup: seq[int]): Net =
    new result
    let lastLayerIdx = setup.len-2
    for i in 0..<setup.len-1:
        result.layers.add(newLayer(setup[i], setup[i+1], i == lastLayerIdx))
        result.weights += (1+setup[i]) * setup[i+1]

func invoke*(x: Net, input: seq[float]): seq[float] =
    result = input
    for layer in x.layers:
        result = layer.invoke(result)

proc correctPredictions*(n: Net, series: Series): int =
    result = 0
    for i, x in series.xs:
        let correct = series.ys[i]
        let neuralGuess = n.invoke(x)
        let bestGuess = argMax(neuralGuess)
        if bestGuess == correct:
            result += 1

proc computeFitness*(n: Net, series: Series, parentInheritance, regularization: float) = 
    n.correct = n.correctPredictions(series)
    let correctFitness = n.correct.toFloat / series.ys.len.toFloat

    var regularizationLoss = 0.0
    if regularization != 0:
        for layer in n.layers:
            for neuron in layer.neurons:
                for weight in neuron.weights:
                    regularizationLoss += weight * weight
    regularizationLoss = (regularizationLoss / n.weights.toFloat) * regularization

    let dataloss = 0.0 # todo

    let batchFitness = correctFitness - regularizationLoss - dataloss
    let parentFitness = n.fitness
    n.fitness = max(parentInheritance * parentFitness + batchFitness, 0.0)

proc mutate*(x: Net, power, frequency: float) =
    for layer in x.layers:
        for neuron in layer.neurons:
            neuron.mutate(power, frequency)

proc pick*(pool: seq[Net], wheel: seq[float]): Net =
    let sum = wheel[wheel.len-1]
    let ran = rand(0.0..sum)
    let idx = wheel.lowerBound(ran, system.cmp[float])
    return pool[idx].deepCopy()

proc crossover*(a: Net, pool: seq[Net], frequency: float, power: HSlice[float, float], wheel: seq[float]) =
    let mate = pick(pool, wheel)
    let crossoverCount = (frequency * a.weights.toFloat).toInt-1

    for i in 0..<crossOverCount:
        let mateRanLayer = rand(0..<mate.layers.len)
        let mateRanNeuron = rand(0..<mate.layers[mateRanLayer].neurons.len)
        let mateRanWeight = rand(0..<mate.layers[mateRanLayer].neurons[mateRanNeuron].weights.len)

        let meRanLayer = rand(0..<a.layers.len)
        let meRanNeuron = rand(0..<a.layers[meRanLayer].neurons.len)
        let meRanWeight = rand(0..<a.layers[meRanLayer].neurons[meRanNeuron].weights.len)

        let crossoverPower = rand(power)
        a.layers[meRanLayer].neurons[meRanNeuron].weights[meRanWeight] = 
            lerp(a.layers[meRanLayer].neurons[meRanNeuron].weights[meRanWeight],
                 mate.layers[mateRanLayer].neurons[mateRanNeuron].weights[mateRanWeight],
                 crossoverPower)

proc computeWheel*(pool: seq[Net]): seq[float] =
    var sum = 0.0
    result = newSeq[float]()
    for net in pool:
        sum += net.fitness
        result.add(sum)