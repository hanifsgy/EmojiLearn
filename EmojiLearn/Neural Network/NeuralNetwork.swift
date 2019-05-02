//
//  NeuralNetwork.swift
//  EmojiLearn
//
//  Created by Hanif Sugiyanto on 02/05/19.
//  Copyright © 2019 Personal Organization. All rights reserved.
//

import Foundation

public class NeuralNetwork {
    
    /// Define learning rate
    public static var learningRate: Float = 0.3
    /// Define momentum to speed up process both training speed and accuracy
    public static var momentum: Float = 0.6
    /// Define iterations
    public static var iterations: Int = 70000
    
    private var layers: [Layer] = []
    
    /// Build up initialzie neural network
    public init(inputSize: Int, hiddenSize: Int, outputSize: Int) {
        self.layers.append(Layer(inputSize: inputSize, outputSize: hiddenSize))
        self.layers.append(Layer(inputSize: hiddenSize, outputSize: outputSize))
    }
    
    public func run(input: [Float]) -> [Float] {
        var activations = input
        
        for i in 0..<layers.count {
            activations = layers[i].run(inputArray: activations)
        }
        
        return activations
    }
    
    public func train(input: [Float], targetOutput: [Float], learningRate: Float, momentum: Float) {
        
        let calculateOutput = run(input: input)
        var error = zip(targetOutput, calculateOutput).map { $0 - $1 }
        
        for i in (0...layers.count - 1).reversed() {
            error = layers[i].train(error: error, learningRate: learningRate, momentum: momentum)
        }
    }
}
