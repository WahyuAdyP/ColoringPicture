//
//  SecondViewController.swift
//  OnixVectorDrawing
//
//  Created by Alexei on 10.05.16.
//  Copyright © 2016 Onix. All rights reserved.
//

import UIKit
import SVGKit
import NKOColorPickerView

struct ONXLayerInfo {
    let x: Float
    let y: Float
    let layer: CAShapeLayer
}

class ViewController: UIViewController {
    @IBOutlet weak var drawView: LayerDrawingView!
    
    let colorPicker: NKOColorPickerView
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        colorPicker = NKOColorPickerView(frame: CGRect.zero, color: UIColor.gray, andDidChangeColorBlock: nil)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        colorPicker = NKOColorPickerView(frame: CGRect.zero, color: UIColor.gray, andDidChangeColorBlock: nil)
        
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        colorPicker.didChangeColorBlock = { color in
            self.color = color
            self.drawView.setFillColor(color!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Color picker", for: UIControl.State())
        button.addTarget(self, action: #selector(colorPickerButtonAction), for: .touchUpInside)
        self.view.addSubview(button)
        
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        
        colorPicker.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(colorPicker)
        colorPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        colorPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        colorPicker.bottomAnchor.constraint(equalTo: button.topAnchor, constant: 0).isActive = true
        colorPicker.heightAnchor.constraint(equalToConstant: 300).isActive = true
        colorPicker.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let url = Bundle.main.url(forResource: "hawaiiFlowers", withExtension: "svg")
        let source = SVGKSourceURL.source(from: url)
        self.setSVGSource(source!)
    }
    @IBOutlet weak var imageView: UIImageView!
    
    @objc func colorPickerButtonAction(_ sender: UIButton) {
        colorPicker.isHidden = !colorPicker.isHidden
    }
    
    func setSVGSource(_ source: SVGKSource) {
        _ = SVGKImage.image(with: source, onCompletion: { loadedImage, parseResult in
            DispatchQueue.main.async(execute: {
                if (loadedImage?.caLayerTree) != nil {
                    self.drawView.drawingLayer = loadedImage?.caLayerTree
                }
            })
        })
    }
    
    var color: UIColor?
}
