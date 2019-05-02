//
//  EmojiViewController.swift
//  EmojiLearn
//
//  Created by Hanif Sugiyanto on 02/05/19.
//  Copyright © 2019 Personal Organization. All rights reserved.
//

import UIKit
import AudioToolbox

class EmojiViewController: UIViewController {
    
    /// ProgressView
    @IBOutlet weak var progressView: UIView!
    /// Segmented Controll
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    /// Status Label
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var drawView: DrawView!
    @IBOutlet weak var btnTeach: UIButton!
    @IBOutlet weak var explainLabel: UILabel!
    @IBOutlet weak var emojiLabel: UILabel!
    
    
    /// GET Section
    fileprivate var currentSection: Section = .teach {
        didSet {
            if currentSection == .play {
                self.emojiLabel.fadeOut(withDuration: 0.3)
                self.btnTeach.fadeOut(withDuration: 0.3)
                self.drawView.clear()
                self.explainLabel.text = "DRAW YOUR SHAPE"
            } else {
                self.emojiLabel.fadeOut(withDuration: 0.3)
                self.btnTeach.fadeIn(withDuration: 0.3)
                self.explainLabel.text = emojis[index].drawText
                self.drawView.clear()
            }
        }
    }
    
    /// Image Processor
    lazy var imgProcessor: ImageProcessor = {
        let imageProc = ImageProcessor()
        return imageProc
    }()
    /// The Emoji Data Set which will be trained
    fileprivate var emojis: [NNEmoji] = {
        return [NNEmoji(emoji: "🙂", drawText: "DRAW A SMILE", buttonText: "TEACH HAPPY"),
                NNEmoji(emoji: "😮", drawText: "DRAW A CIRCLE", buttonText: "TEACH DAMN"),
                NNEmoji(emoji: "😍", drawText: "DRAW A HEART", buttonText: "TEACH LOVE"),
                NNEmoji(emoji: "😴", drawText: "DRAW A ZED", buttonText: "TEACH SLEEPY"),
                NNEmoji(emoji: "😐", drawText: "DRAW A LINE", buttonText: "TEACH POKER FACE"),
                NNEmoji(emoji: "☹️", drawText: "DRAW A FROWN", buttonText: "TEACH SAD")]
    }()
    /// The Neural Network 🚀
    fileprivate lazy var neuralNetwork: NeuralNetwork = {
        let neuralNetWork = NeuralNetwork(inputSize: 64, hiddenSize: 15, outputSize: 6)
        
        return neuralNetWork
    }()
    
    // The Network is Ready to predict
    fileprivate var isReady: Bool = false
    
    // The Training Data for the input neuron
    fileprivate var trainingData: [[Float]] = [] {
        didSet {
            if trainingData.count == 12 { statusLabel.textColor = UIColor.white }
            if trainingData.count == 18 {
                // tell selected segment control
                self.segmentedControl.selectedSegmentIndex = 1
                self.segmentedControl.sendActions(for: .valueChanged)
                currentSection = .play
                statusLabel.text = "🤖 LEARNING AND THINKING 💭"
                statusLabel.startBlink()
                learnNetwork()
            }
            progressView.frame = CGRect(x: 0, y: 0, width: Double(self.view.frame.width) /  (Double(18) / Double(trainingData.count)), height: 48)
        }
    }
    
    /// The Result Data labels for the output
    fileprivate var trainingResults: [[Float]] = []
    
    /// The index to update the UI
    fileprivate var index: Int = 0  {
        didSet {
            emojiLabel.text = emojis[index].emoji
            explainLabel.text = emojis[index].drawText
            btnTeach.setTitle(emojis[index].buttonText, for: .normal)
        }
    }
    
    /// The Play Section Button
    fileprivate lazy var emojiAnimationLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = true
        label.text = "🙂"
        label.font = UIFont.systemFont(ofSize: 70.0)
        
        return label
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawView.delegate = self
        
        self.view.addSubview(emojiAnimationLabel)
        
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.currentSection = .teach
            self.emojiAnimationLabel.isHidden = true
        }
        
        segmentedControl.addTarget(self, action: #selector(handleSegment(sender:)), for: .valueChanged)
        btnTeach.addTarget(self, action: #selector(handleTeach(sender:)), for: .touchUpInside)
        
        /// for first purpose initial teach
        btnTeach.setTitle(emojis[0].buttonText, for: .normal)
    }

    
    @objc private func handleSegment(sender: UISegmentedControl) {
        print("Sender: \(sender.selectedSegmentIndex)")
        if sender.selectedSegmentIndex == 0 {
            self.currentSection = .teach
            self.emojiAnimationLabel.isHidden = true
        } else {
            self.currentSection = .play
        }
    }
    
    @objc private func handleTeach(sender: UIButton) {
        self.btnTeach.isHidden = true
        self.explainLabel.isHidden = false
        self.addNeuronData(input: self.returnImageBlock())
        index = index == 5 ? 0 : index+1
    }
}

extension EmojiViewController {
    
    
    func addNeuronData(input: [Float]) {
        var trainingResults: [[Float]] = [
            [1,0,0,0,0,0], // 🙂
            [0,1,0,0,0,0], // 😮
            [0,0,1,0,0,0], // 😍
            [0,0,0,1,0,0], // 😴
            [0,0,0,0,1,0], // 😐
            [0,0,0,0,0,1]  // ☹️
        ]
        self.trainingResults.append(trainingResults[index])
        self.trainingData.append(input)
        self.drawView.clear()
    }
    
    /// Learn the Networks
    func learnNetwork() {
        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            for iterations in 0..<NeuralNetwork.iterations {
                for i in 0..<self.trainingResults.count {
                    self.neuralNetwork.train(input: self.trainingData[i], targetOutput: self.trainingResults[i], learningRate: NeuralNetwork.learningRate, momentum: NeuralNetwork.momentum)
                }
                
                for i in 0..<self.trainingResults.count {
                    let data = self.trainingData[i]
                    let _ = self.neuralNetwork.run(input: data)
                }
                
                print("Iterations epoch: \(iterations)")
            }
            
            self.isReady = true
            
            DispatchQueue.main.async {
                self.statusLabel.stopBlink()
                self.statusLabel.text = "🎨 Start drawing..."
            }
        }
    }
    
    /// Predict the Models
    func predict(inputData: [Float]) {
        guard let img = self.drawView.getImage() else { return }
        
        let x = imgProcessor.centerOf(image: img).midX
        let y = imgProcessor.centerOf(image: img).midY
        
        let prediction = self.neuralNetwork.run(input: inputData).filter { $0 >= 0.8 }
        self.emojiAnimationLabel.isHidden = false
        self.emojiAnimationLabel.center = CGPoint(x: x, y: y)
        
        if prediction.count == 0 {
            self.emojiAnimationLabel.transformAnimation()
            self.emojiAnimationLabel.text = "😶"
            SystemSoundID.playFileNamed(fileName: "wrong", withExtenstion: "wav")
        } else {
            self.neuralNetwork.run(input: inputData).enumerated().forEach { index, element in
                if element >= 0.8 {
                    self.emojiAnimationLabel.transformAnimation()
                    self.emojiAnimationLabel.text = self.emojis[index].emoji
                    SystemSoundID.playFileNamed(fileName: "correct", withExtenstion: "wav")
                }
            }
        }
        self.drawView.clear()
    }
    
}

/// MARK: - Delegate from DrawView

extension EmojiViewController: DrawViewDelegate {
    
    func drawViewDidFinishDrawing(view: DrawView) {
        if self.currentSection == .play && self.isReady {
            predict(inputData: self.returnImageBlock())
        }
    }
    
    func drawViewMoved(view: DrawView) {
        self.btnTeach.isHidden = false
        self.explainLabel.isHidden = true
    }
    
    func returnImageBlock() -> [Float] {
        guard let image = self.drawView.getImage(), let mnistImage = self.imgProcessor.resize(image: image) else { return [] }
        print("Image processor: \(self.imgProcessor.imageBlock(image: mnistImage))")
        print("Image processor count: \(self.imgProcessor.imageBlock(image: mnistImage).count)")
        return self.imgProcessor.imageBlock(image: mnistImage)
    }
}
