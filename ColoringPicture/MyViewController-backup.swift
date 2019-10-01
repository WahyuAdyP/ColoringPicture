//
//  MyViewController.swift
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 12/28/17.
//  Copyright © 2017 Crocodic. All rights reserved.
//

import UIKit
import SVGKit

class MyViewController_BU: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionColorView: UICollectionView!
    @IBOutlet weak var scrollBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var undoBtn: UIButton!
    @IBOutlet weak var redoBtn: UIButton!
    @IBOutlet weak var containerColor: UIView!
    
    var paintView: PaintingImageView!
    var drawView: LayerDrawingView!
    var floodView: FloodFillImageView!
    
    var historyLayer = [Any]()
    var panHistoryLayers = [LayerPiece]()
    var currentPosition = 0
    
    var colors = [UIColor]()
    var gradientColors = [[UIColor]]()
    var selectedColor: UIColor = UIColor.init(red: 17/255, green: 17/255, blue: 17/255, alpha: 1.0)
    
    var imageUrl: URL?
    var imgName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        
        collectionColorView.delegate = self
        collectionColorView.dataSource = self
        
        colors = [
            UIColor.red,
            UIColor.orange,
            UIColor.yellow,
            UIColor.purple,
            UIColor.magenta,
            UIColor.blue,
            UIColor.cyan,
            UIColor.green,
            UIColor.brown,
            UIColor.init(red: 17/255, green: 17/255, blue: 17/255, alpha: 1.0),
            UIColor.darkGray,
            UIColor.gray,
            UIColor.lightGray
        ]
        
        gradientColors = [
            [UIColor.white, UIColor.red],
            [UIColor.white, UIColor.orange],
            [UIColor.white, UIColor.yellow],
            [UIColor.white, UIColor.magenta],
            [UIColor.white, UIColor.blue],
            [UIColor.white, UIColor.cyan],
            [UIColor.white, UIColor.green],
            [UIColor.white, UIColor.brown],
            [UIColor.white, UIColor.black],
            [UIColor.white, UIColor.darkGray],
            [UIColor.white, UIColor.gray],
            [UIColor.white, UIColor.lightGray]
        ]
        collectionColorView.reloadData()
        
        let indexPath = IndexPath(item: 0, section: 0)
        collectionColorView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
        
        shareBtn.addTarget(self, action: #selector(tapBtn(_:)), for: .touchUpInside)
        resetBtn.addTarget(self, action: #selector(reset(_:)), for: .touchUpInside)
        undoBtn.addTarget(self, action: #selector(undo(_:)), for: .touchUpInside)
        redoBtn.addTarget(self, action: #selector(redo(_:)), for: .touchUpInside)
        scrollBtn.addTarget(self, action: #selector(coloring(_:)), for: .touchUpInside)
        
        view.backgroundColor = UIColor.green
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        setImageOpenCV()
        
//        self.setSVGSource(imageUrl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func convertPointToImage(imageView: UIImageView, imageViewPoint: CGPoint)->CGPoint{
        var scale : CGFloat = 1
        if let superView = imageView.superview as? UIScrollView{
            scale = superView.zoomScale
        }
        let x = Int(imageView.image!.size.width * imageViewPoint.x * scale / imageView.frame.size.width)
        let y = Int(imageView.image!.size.height * imageViewPoint.y * scale / imageView.frame.size.height)
        
        return CGPoint(x: x, y: y)
        
    }
    
    fileprivate func createARGBBitmap(image: UIImage) -> UIImage? {
        let pixelsWide = image.cgImage?.width
        let pixelsHigh = image.cgImage?.height
        let bitmapBytesPerRow = pixelsWide! * 4
        let bitmapByteCount = bitmapBytesPerRow * pixelsHigh!
        guard CGColorSpace(name: CGColorSpace.genericRGBLinear) != nil else{
            print("Error allocating color space")
            return nil
        }
        let bitmapData = malloc(bitmapByteCount)
        guard let context = CGContext(data: bitmapData, width: pixelsWide!, height: pixelsHigh!, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            print("Context not create")
            return nil
        }
        
        context.clear(CGRect(x: 0, y: 0, width: pixelsWide!, height: pixelsHigh!))
        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: pixelsWide!, height: pixelsHigh!))
        
        guard let decodedImage = context.makeImage() else { return nil }
        let img = UIImage(cgImage: decodedImage, scale: image.scale, orientation: image.imageOrientation)
        
        return img
    }
    
    @objc func tapToFill(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: paintView)
        
        let newPoint = convertPointToImage(imageView: paintView, imageViewPoint: point)
        let color = paintView.image!.getPixelColor(point: newPoint)
        
        containerColor.backgroundColor = color
        if color.isEqual(to: selectedColor, strict: false) || color.isEqual(to: UIColor.black, strict: false) {
            return
        }
        
        let layerPiece = LayerPiece(point: point, undoColor: color, redoColor: selectedColor)
        
        if currentPosition == historyLayer.count {
            historyLayer.append(layerPiece)
        } else {
            var indexRemove = currentPosition
            while indexRemove < historyLayer.count {
                historyLayer.remove(at: indexRemove)
                indexRemove += 1
            }
            historyLayer.append(layerPiece)
        }
        currentPosition = historyLayer.count
        paintView.buckerFill(point, replacementColor: selectedColor)
    }
    
    @objc func panToFill(_ sender: UIPanGestureRecognizer) {
        if scrollView.isScrollEnabled {
            return
        }
        if sender.state == .began {
            panHistoryLayers = [LayerPiece]()
        }
        
        let point = sender.location(in: paintView)
        
        let newPoint = convertPointToImage(imageView: paintView, imageViewPoint: point)
        
        if !paintView.bounds.contains(point) {
            
            return
        }
        
        let color = paintView.image!.getPixelColor(point: newPoint)
        containerColor.backgroundColor = color
        
        if !color.isEqual(to: selectedColor, strict: false) && !color.isEqual(to: UIColor.black, strict: false) {
            
            let layerPiece = LayerPiece(point: point, undoColor: color, redoColor: selectedColor)
            panHistoryLayers.append(layerPiece)
            
            paintView.buckerFill(point, replacementColor: selectedColor)
        }
        
        if sender.state == .ended {
            print(panHistoryLayers.count)
            if currentPosition == historyLayer.count {
                historyLayer.append(panHistoryLayers)
            } else {
                var indexRemove = currentPosition
                while indexRemove < historyLayer.count {
                    historyLayer.remove(at: indexRemove)
                    indexRemove += 1
                }
                historyLayer.append(panHistoryLayers)
            }
            currentPosition = historyLayer.count
        }
    }
    
    @objc func tapBtn(_ button: UIButton) {
        UIGraphicsBeginImageContextWithOptions(drawView.bounds.size, false, 0.0)
        drawView.drawHierarchy(in: drawView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            let shareObject: [Any] = [image]
            let activityVC = UIActivityViewController(activityItems: shareObject, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @objc func reset(_ button: UIButton) {
//        drawView.updateColor(when: .reset)
    }
    
    @objc func coloring(_ button: UIButton) {
        scrollView.isScrollEnabled = !scrollView.isScrollEnabled
        
        button.setTitle(scrollView.isScrollEnabled ? "Swipe: off" : "Swipe: on", for: .normal)
    }
    
    func animateMultiColor(currentIndex: Int, endIndex: Int, data: [LayerPiece]) {
        self.paintView.isUserInteractionEnabled = false
        self.undoBtn.isUserInteractionEnabled = false
        self.redoBtn.isUserInteractionEnabled = false
        
        let aHistory = data[currentIndex]
        let isUndo = endIndex == 0
        let color = isUndo ? aHistory.undoColor : aHistory.redoColor
        self.paintView.buckerFill(aHistory.point, replacementColor: color!)
        
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.017) {
            if isUndo && currentIndex - 1 >= endIndex {
                self.animateMultiColor(currentIndex: currentIndex - 1, endIndex: endIndex, data: data)
            } else if !isUndo && currentIndex < endIndex - 1 {
                self.animateMultiColor(currentIndex: currentIndex + 1, endIndex: endIndex, data: data)
            } else {
                print("Finish")
                self.paintView.isUserInteractionEnabled = true
                self.undoBtn.isUserInteractionEnabled = true
                self.redoBtn.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc func undo(_ button: UIButton) {
        if currentPosition > 0 {
            currentPosition -= 1
            if let aHistory = historyLayer[currentPosition] as? LayerPiece {
                print("Undo one layers")
                paintView.buckerFill(aHistory.point, replacementColor: aHistory.undoColor)
            }
            if let aHistories = historyLayer[currentPosition] as? [LayerPiece] {
                print("Undo multi layers")
                let i = aHistories.count - 1
                animateMultiColor(currentIndex: i, endIndex: 0, data: aHistories)
//                while i >= 0 {
//                    let aHistory = aHistories[i]
//                    paintView.buckerFill(aHistory.point, replacementColor: aHistory.undoColor)
//                    i -= 1
//                }
            }
        }
//        drawView.undoColoring()
    }
    
    @objc func redo(_ button: UIButton) {
        if currentPosition < historyLayer.count {
            if let aHistory = historyLayer[currentPosition] as? LayerPiece {
                print("Redo one layers")
                paintView.buckerFill(aHistory.point, replacementColor: aHistory.redoColor)
            }
            
            if let aHistories = historyLayer[currentPosition] as? [LayerPiece] {
                print("Redo multi layers")
                animateMultiColor(currentIndex: 0, endIndex: aHistories.count, data: aHistories)
//                for aHistory in aHistories {
//                    self.paintView.buckerFill(aHistory.point, replacementColor: aHistory.redoColor)
//                }
            }
            currentPosition += 1
        }
//        drawView.redoColoring()
    }
    
    func setSVGSource(_ url: URL?) {
        let source = SVGKSourceURL.source(from: url)
        _ = SVGKImage.image(with: source, onCompletion: { loadedImage, parseResult in
            DispatchQueue.main.async(execute: {
                if let img = loadedImage {
                    let scrollViewSize = self.scrollView.frame.size
                    let imgSize = img.uiImage.size
                    
                    var newWidth: CGFloat = 0
                    var newHeight: CGFloat = 0
                    var scaling: CGFloat = 0
                    if imgSize.width > imgSize.height {
                        newWidth = scrollViewSize.width - 40
                        newHeight = imgSize.height * newWidth / imgSize.width
                        
                        scaling = newWidth / imgSize.width
                    } else {
                        newHeight = scrollViewSize.height - 40
                        newWidth = imgSize.width * newHeight / imgSize.height
                        
                        scaling = newHeight / imgSize.height
                    }

                    let point = CGPoint(x: 0, y: 0)
                    let size = CGSize(width: newWidth, height: newHeight)
                    let drawViewFrame = CGRect(origin: point, size: size)
                    
                    self.drawView = LayerDrawingView(frame: drawViewFrame)
                    self.drawView.scaleForCTM = scaling
                    self.drawView.drawingLayer = img.caLayerTree
                    self.drawView.savedIdentifier = (url?.lastPathComponent)!
                    
                    self.scrollView.addSubview(self.drawView)

                    self.setZoomScale()
                    
                    self.drawView.updateColor(when: .last)
                }
            })
        })
        
    }
    
    func setImageFromFloodFillManual() {
        let image = UIImage(named: "minion_scatch.jpg")!
        let newWidth: CGFloat = 300
        let newHeight = image.size.height * newWidth / image.size.width
        
        floodView = FloodFillImageView(frame: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        floodView.isUserInteractionEnabled = true
        floodView.image = image
        floodView.newColor = UIColor.red
        floodView.tolorance = 30
        self.scrollView.addSubview(floodView)
        
        setZoomScale()
    }
    
    func setImageOpenCV() {
        let image = UIImage(named: imgName)!
        
        let imageCV = OpenCVWrapper.scanImage(image)
        let argbImg = createARGBBitmap(image: imageCV!)
        
        let newWidth: CGFloat = self.scrollView.frame.width - 40
        let newHeight = image.size.height * newWidth / image.size.width
        paintView = PaintingImageView(frame: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        paintView.isUserInteractionEnabled = true
        paintView.image = argbImg
        self.scrollView.addSubview(paintView)
        
        print(argbImg?.size ?? .zero)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapToFill(_:)))
        paintView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panToFill(_:)))
        paintView.addGestureRecognizer(panGesture)
        
        setZoomScale()
    }
    
    func setZoomScale() {
        let imageViewSize = paintView.frame.size
        let scrollViewSize = scrollView.frame.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        scrollView.minimumZoomScale = min(widthScale, heightScale) * 4 / 5
        scrollView.maximumZoomScale = max(widthScale, heightScale) * 5
        scrollView.zoomScale = min(widthScale, heightScale) * 4 / 5
    }
    
    func fillGradient(in point: CGPoint) {
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MyViewController_BU: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return paintView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageViewSize = paintView.frame.size
        let scrollViewSize = scrollView.frame.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
}

extension MyViewController_BU: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count + gradientColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: indexPath) as! ColorCell
        if indexPath.item < colors.count {
            cell.backgroundColor = colors[indexPath.item]
        } else {
            let cgColors = gradientColors[indexPath.item - colors.count].map { $0.cgColor }
            let radianColor = RadianGradientLayer(
                center: CGPoint(x: cell.frame.width / 2, y: cell.frame.height / 2),
                radius: cell.frame.width / 2,
                colors: cgColors
            )
            radianColor.frame = cell.bounds
            radianColor.name = "gradientLayer"
            cell.layer.insertSublayer(radianColor, at: 0)
        }
        return cell
    }
}

extension MyViewController_BU: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < colors.count {
            self.selectedColor = colors[indexPath.item]
//            drawView.setFillColor(colors[indexPath.item])
        } else {
//            self.selectedColor = gradientColors[indexPath.item - colors.count]
//            drawView.setGradientColor(gradientColors[indexPath.item - colors.count])
        }
    }
}
