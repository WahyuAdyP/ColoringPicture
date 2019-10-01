//
//  LayerDrawingView.swift
//  OnixVectorDrawing
//
//  Created by Alexei on 11.05.16.
//  Copyright © 2016 Onix. All rights reserved.
//

import Foundation
import UIKit

class LayerPiece: NSObject, NSCoding {
    var point: CGPoint!
    var undoIsGradient: Bool {
        return undoGradient != nil && !undoGradient.isEmpty
    }
    var redoIsGradient: Bool {
        return redoGradient != nil && !redoGradient.isEmpty
    }
    var undoColor: UIColor!
    var redoColor: UIColor!
    var undoGradient: [UIColor]!
    var redoGradient: [UIColor]!
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        
        self.point = aDecoder.decodeCGPoint(forKey: "point")
        if let undoColor = aDecoder.decodeObject(forKey: "undoColor") as? UIColor { self.undoColor = undoColor }
        if let redoColor = aDecoder.decodeObject(forKey: "redoColor") as? UIColor { self.redoColor = redoColor }
        if let undoGradient = aDecoder.decodeObject(forKey: "undoGradient") as? [UIColor] { self.undoGradient = undoGradient }
        if let redoGradient = aDecoder.decodeObject(forKey: "redoGradient") as? [UIColor] { self.redoGradient = redoGradient }
    }
    
    convenience init(point: CGPoint, undoColor: UIColor, redoColor: UIColor) {
        self.init()
        self.point = point
        self.undoColor = undoColor
        self.redoColor = redoColor
    }
    
    convenience init(point: CGPoint, undoGradient: [UIColor], redoGradient: [UIColor]) {
        self.init()
        self.point = point
        self.undoGradient = undoGradient
        self.redoGradient = redoGradient
    }
    
    func encode(with coder: NSCoder) {
        if let point = point { coder.encode(point, forKey: "point") }
        if let undoColor = undoColor { coder.encode(undoColor, forKey: "undoColor") }
        if let redoColor = redoColor { coder.encode(redoColor, forKey: "redoColor") }
        if let undoGradient = undoGradient { coder.encode(undoGradient, forKey: "undoGradient") }
        if let redoGradient = redoGradient { coder.encode(redoGradient, forKey: "redoGradient") }
    }
}

class LayerDrawingView: UIView, UIScrollViewDelegate {
    var savedIdentifier: String = ""
    
    var drawingLayer: CALayer? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    fileprivate var fillColor = UIColor.red
    func setFillColor(_ color: UIColor) {
        fillColor = color
        isGradient = false
    }
    
    fileprivate var isGradient = false
    fileprivate var gradientColor = [UIColor.white, UIColor.red]
    func setGradientColor(_ colors: [UIColor]) {
        gradientColor = colors
        isGradient = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    var historyLayer: [LayerPiece] = [LayerPiece]()
    var currentPosition = 0
    
    fileprivate func setup() {
        
        self.backgroundColor = UIColor.white
        self.clearsContextBeforeDrawing = true
        
        _ = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
//        self.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        pan.minimumNumberOfTouches = 1
//        self.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        tap.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tap)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let layer = drawingLayer, let context = UIGraphicsGetCurrentContext() {
            context.scaleBy(x: scaleForCTM, y: scaleForCTM)
            context.translateBy(x: translateForCTM.x, y: translateForCTM.y)
            
            layer.render(in: context)
        }
    }
    
    var lastPinchScale: CGFloat = 1.0
    var scaleForCTM: CGFloat = 1.0
    
    fileprivate var lastPanTranslate = CGPoint.zero
    fileprivate var translateForCTM = CGPoint.zero
    
    func undoColoring() {
        if currentPosition > 0 {
            currentPosition -= 1
            let aHistory = historyLayer[currentPosition]
            if let layer = self.drawingLayer?.hitTest(aHistory.point) as? CAShapeLayer {
                let gradientLayer = layer.sublayers?[0] as? RadianGradientLayer
                
                if !aHistory.undoIsGradient {
                    layer.fillColor = aHistory.undoColor.cgColor
                    if gradientLayer != nil && gradientLayer!.name == "gradientColor" {
                        gradientLayer!.removeFromSuperlayer()
                    }
                } else {
                    updateGradientColor(in: layer, center: aHistory.point, colors: aHistory.undoGradient)
                }
                
                self.setNeedsDisplay()
            }
        }
    }
    
    func redoColoring() {
        if currentPosition < historyLayer.count {
            let aHistory = historyLayer[currentPosition]
            if let layer = self.drawingLayer?.hitTest(aHistory.point) as? CAShapeLayer {
                let gradientLayer = layer.sublayers?[0] as? RadianGradientLayer
                
                if !aHistory.redoIsGradient {
                    layer.fillColor = aHistory.redoColor.cgColor
                    if gradientLayer != nil && gradientLayer!.name == "gradientColor" {
                        gradientLayer!.removeFromSuperlayer()
                    }
                } else {
                    updateGradientColor(in: layer, center: aHistory.point, colors: aHistory.redoGradient)
                }
                
                self.setNeedsDisplay()
            }
            currentPosition += 1
        }
    }
    
    enum WhenColor {
        case reset
        case last
    }
    
    func updateColor(when color: WhenColor) {
        guard let lastData = UserDefaults.standard.data(forKey: savedIdentifier) else { return }
        guard let loadedArray = NSKeyedUnarchiver.unarchiveObject(with: lastData) as? [LayerPiece] else { return }
        historyLayer = loadedArray
        currentPosition = historyLayer.count
        
        switch color {
        case .reset:
            var i = historyLayer.count - 1
            while i >= 0 {
                let aHistory = historyLayer[i]
                if let layer = self.drawingLayer?.hitTest(aHistory.point) as? CAShapeLayer {
                    let gradientLayer = layer.sublayers?[0] as? RadianGradientLayer
                    if !aHistory.undoIsGradient {
                        layer.fillColor = aHistory.undoColor.cgColor
                        if gradientLayer != nil && gradientLayer!.name == "gradientColor" {
                            gradientLayer!.removeFromSuperlayer()
                        }
                    } else {
                        updateGradientColor(in: layer, center: aHistory.point, colors: aHistory.undoGradient)
                    }
                }
                i -= 1
            }
        default:
            for aHistory in historyLayer {
                if let layer = self.drawingLayer?.hitTest(aHistory.point) as? CAShapeLayer {
                    let gradientLayer = layer.sublayers?[0] as? RadianGradientLayer
                    if !aHistory.redoIsGradient {
                        layer.fillColor = aHistory.redoColor.cgColor
                        if gradientLayer != nil && gradientLayer!.name == "gradientColor" {
                            gradientLayer!.removeFromSuperlayer()
                        }
                    } else {
                        updateGradientColor(in: layer, center: aHistory.point, colors: aHistory.redoGradient)
                    }
                }
            }
        }

        if color == .reset {
            historyLayer.removeAll()
            currentPosition = historyLayer.count
            saveData()
        }
        
        
        self.setNeedsDisplay()
    }
    
    func updateGradientColor(in layer: CAShapeLayer, center: CGPoint, colors: [UIColor]) {
        if let gradientLayer = layer.sublayers?[0] as? RadianGradientLayer, gradientLayer.name == "gradientColor" {
            let newPoint = CGPoint(x: center.x - layer.frame.origin.x, y: center.y - layer.frame.origin.y)
            gradientLayer.center = newPoint
            gradientLayer.colors = colors.map { $0.cgColor }
        } else {
            let cgColors = colors.map { $0.cgColor }
            
            let newPoint = CGPoint(x: center.x - layer.frame.origin.x, y: center.y - layer.frame.origin.y)
            
            let gradientLayer = RadianGradientLayer(center: newPoint, radius: min(layer.bounds.width, layer.bounds.height) / 2, colors: cgColors)
            gradientLayer.name = "gradientColor"
            gradientLayer.frame = layer.bounds
            layer.insertSublayer(gradientLayer, at: 0)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = layer.path
            shapeLayer.fillColor = UIColor.black.cgColor
            
            gradientLayer.mask = shapeLayer
        }
    }
    
    func saveData() {
        let data = NSKeyedArchiver.archivedData(withRootObject: historyLayer)
        if historyLayer.isEmpty {
            UserDefaults.standard.removeObject(forKey: savedIdentifier)
        } else {
            UserDefaults.standard.set(data, forKey: savedIdentifier)
        }
    }
    
    @objc func pinchGesture(_ sender: UIPinchGestureRecognizer) {
        if (sender.state == .began) {
            lastPinchScale = 1.0
        }
        
        // Scale
        let scaleDiff = sender.scale - lastPinchScale
        let scaling = scaleDiff * scaleForCTM
        
        scaleForCTM += scaling
        
        lastPinchScale = sender.scale
        
        self.setNeedsDisplay()
    }
    
    @objc func panGesture(_ sender: UIPanGestureRecognizer) {
        if (sender.state == .began) {
            lastPanTranslate = CGPoint.zero
        }
        
        let translation = sender.translation(in: self)
        let translateDiff = CGPoint(x: translation.x - lastPanTranslate.x, y: translation.y - lastPanTranslate.y)
        
        translateForCTM = CGPoint(x: translateForCTM.x + (translateDiff.x / scaleForCTM), y: translateForCTM.y + (translateDiff.y / scaleForCTM))
        
        
        lastPanTranslate = translation
        
        self.setNeedsDisplay()
    }
    
    @objc func tapGesture(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self)
        let scaleTransform = CGAffineTransform(scaleX: 1 / scaleForCTM, y: 1 / scaleForCTM)
        let scaledPoint = point.applying(scaleTransform)
        let translateTransform = CGAffineTransform(translationX: -translateForCTM.x, y: -translateForCTM.y)
        let translatedPoint = scaledPoint.applying(translateTransform)
        
        if let layer = self.drawingLayer?.hitTest(translatedPoint) as? CAShapeLayer {
            let prevColor = layer.fillColor != nil ? UIColor(cgColor: layer.fillColor!) : UIColor.white
            let gradientLayer = layer.sublayers?[0] as? RadianGradientLayer
            var prevGradientColor: [UIColor] {
                var colors = [UIColor]()
                if let gLayer = gradientLayer {
                    colors = gLayer.colors.map { UIColor(cgColor: $0) }
                }
                return colors
            }
            
            let prevLayer = LayerPiece()
            prevLayer.point = translatedPoint
//            if !isGradient {
                prevLayer.undoColor = prevColor
                prevLayer.redoColor = fillColor
//            } else {
                prevLayer.undoGradient = prevGradientColor
                prevLayer.redoGradient = gradientColor
//            }
            
            if currentPosition == historyLayer.count {
                historyLayer.append(prevLayer)
            } else {
                var indexRemove = currentPosition
                while indexRemove < historyLayer.count {
                    historyLayer.remove(at: indexRemove)
                    indexRemove += 1
                }
                historyLayer.append(prevLayer)
            }
            currentPosition = historyLayer.count
            
            if !isGradient {
                layer.fillColor = fillColor.cgColor
                if gradientLayer != nil && gradientLayer!.name == "gradientColor" {
                    gradientLayer!.removeFromSuperlayer()
                }
            } else {
                updateGradientColor(in: layer, center: translatedPoint, colors: gradientColor)
            }
            
            saveData()

        }
        
        self.setNeedsDisplay()
    }
}
