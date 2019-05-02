//
//  ActivationFunction.swift
//  EmojiLearn
//
//  Created by Hanif Sugiyanto on 02/05/19.
//  Copyright © 2019 Personal Organization. All rights reserved.
//

import Foundation

public class ActivationFunction {
    /// Sigmoid function y=1/(1+e^(-x))
    static func sigmoid(x: Float) -> Float {
        return 1 / (1 + exp(-x))
    }
    
    static func sigmoidDerivative(x: Float) -> Float {
        return x * (1 - x)
    }
}
