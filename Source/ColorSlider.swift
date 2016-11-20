//
//  ColorSlider.swift
//
//  Created by Sachin Patel on 1/11/15.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015-Present Sachin Patel (http://gizmosachin.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

///	Create and add an instance of  ColorSlider to your view hierarchy.
///
///	``` Swift
///	let colorSlider = ColorSlider()
///	colorSlider.frame = CGRectMake(0, 0, 12, 150)
///	view.addSubview(colorSlider)
///	```
///
///	ColorSlider is a subclass of `UIControl` and supports the following `UIControlEvents`:
///	- `.TouchDown`
///	- `.ValueChanged`
///	- `.TouchUpInside`
///	- `.TouchUpOutside`
///	- `.TouchCancel`
///
///	You can get the currently selected color with the `color` property.
///	```
///	colorSlider.addTarget(self, action: "changedColor:", forControlEvents: .ValueChanged)
///
///	func changedColor(slider: ColorSlider) {
///	var color = slider.color
///	// ...
///	}
///	```
///
///	Enable live color preview:
///	```
///	colorSlider.previewEnabled = true
///	```
///
///	Customize appearance:
///	```
///	colorSlider.orientation = .Horizontal
///	colorSlider.borderWidth = 2.0
///	colorSlider.borderColor = UIColor.whiteColor()
///	```

import UIKit
import Foundation
import CoreGraphics

@IBDesignable open class ColorSlider: UIControl {
    
    /// The current color of the `ColorSlider`.
    open var color: UIColor {
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    // MARK: Customization
    /// The display orientation of the `ColorSlider`.
    public enum Orientation {
        /// Displays `ColorSlider` vertically.
        case vertical
        
        /// Displays `ColorSlider` horizontally.
        case horizontal
    }
    
    /// The orientation of the `ColorSlider`. Defaults to `.Vertical`.
    open var orientation: Orientation = .vertical {
        didSet {
            switch orientation {
            case .vertical:
                drawLayer.startPoint = CGPoint(x: 0.5, y: 1)
                drawLayer.endPoint = CGPoint(x: 0.5, y: 0)
            case .horizontal:
                drawLayer.startPoint = CGPoint(x: 0, y: 0.5)
                drawLayer.endPoint = CGPoint(x: 1, y: 0.5)
            }
        }
    }
    
    /// A boolean value that determines whether or not a color preview is shown while dragging.
    @IBInspectable open var previewEnabled: Bool = false
    
    /// The width of the ColorSlider's border.
    @IBInspectable open var borderWidth: CGFloat = 1.0 {
        didSet {
            drawLayer.borderWidth = borderWidth
        }
    }
    
    /// The color of the ColorSlider's border.
    @IBInspectable open var borderColor: UIColor = UIColor.black {
        didSet {
            drawLayer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable open var baseColor = UIColor(red: 59/255.0, green: 123/255.0, blue: 218/255.0, alpha: 1) {
        didSet {
            setUpBaseColor()
        }
    }
    
    // MARK: Internal
    /// Internal `CAGradientLayer` used for drawing the `ColorSlider`.
    fileprivate var drawLayer: CAGradientLayer = CAGradientLayer()
    
    /// The hue of the current color.
    fileprivate var hue: CGFloat = 0
    
    /// The saturation of the current color.
    fileprivate var saturation: CGFloat = 1
    fileprivate var originalSaturation: CGFloat = 1
    fileprivate var minimumSaturation: CGFloat = 0.4
    
    /// The brightness of the current color.
    fileprivate var brightness: CGFloat = 1
    fileprivate var originalBrightness: CGFloat = 1
    fileprivate var minimumBrightness: CGFloat = 0.4
    
    // MARK: Preview view
    /// The color preview view. Only shown if `previewEnabled` is set to `true`.
    fileprivate var previewView: UIView = UIView()
    
    /// The edge length of the preview view.
    fileprivate let previewDimension: CGFloat = 30
    
    /// The amount that the `previewView` is drawn away from the `ColorSlider` bar.
    fileprivate let previewOffset: CGFloat = 44
    
    /// The duration of the preview show or hide animation.
    fileprivate let previewAnimationDuration: TimeInterval = 0.10
    
    // MARK: - Initializers
    /// Creates a `ColorSlider` with a frame of `CGRect.zero`.
    public init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }
    
    /// Creates a `ColorSlider` with a frame of `frame`.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    /// Creates a `ColorSlider` from Interface Builder.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    /// Sets up internal views.
    open func commonInit() {
        backgroundColor = UIColor.clear
        
        drawLayer.masksToBounds = true
        drawLayer.cornerRadius = 3.0
        drawLayer.borderColor = borderColor.cgColor
        drawLayer.borderWidth = borderWidth
        drawLayer.startPoint = CGPoint(x: 0.5, y: 1)
        drawLayer.endPoint = CGPoint(x: 0.5, y: 0)
        
        // Draw gradient
        //		let hues: [CGFloat] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
        //		drawLayer.locations = hues
        //		drawLayer.colors = hues.map({ (hue) -> CGColor in
        //			return UIColor(hue: hue, saturation: 0.7, brightness: 1, alpha: 1).CGColor
        //		})
        
        setUpBaseColor()
        
        previewView.clipsToBounds = true
        previewView.layer.cornerRadius = previewDimension / 2
        previewView.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
        previewView.layer.borderWidth = 1.0
    }
    
    fileprivate func setUpBaseColor() {
        
        hue = self.baseColor.hsba.h
        saturation = self.baseColor.hsba.s
        originalSaturation = saturation
        minimumSaturation = saturation * 0.4
        brightness = self.baseColor.hsba.b
        originalBrightness = brightness
        minimumBrightness = brightness * 0.4
        
        let locations:[CGFloat] = [0.0, 0.5, 1.0]
        drawLayer.locations = locations as [NSNumber]?
        drawLayer.colors = [UIColor(hue: hue, saturation: minimumSaturation, brightness: originalBrightness, alpha: 1.0).cgColor, UIColor(hue: hue, saturation: originalSaturation, brightness: originalBrightness, alpha: 1.0).cgColor, UIColor(hue: hue, saturation: originalSaturation, brightness: minimumBrightness, alpha: 1.0).cgColor]
    }
    
    // MARK: - UIControl
    /// Begins tracking a touch when the user drags on the `ColorSlider`.
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        
        // Reset saturation and brightness
//        saturation = 0.7
//        brightness = 1.0
        
        updateForTouch(touch, touchInside: true)
        
        showPreview(touch)
        
        sendActions(for: .touchDown)
        return true
    }
    
    /// Continues tracking a touch as the user drags on the `ColorSlider`.
    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        
        updateForTouch(touch, touchInside: isTouchInside)
        
        updatePreview(touch)
        
        sendActions(for: .valueChanged)
        return true
    }
    
    /// Ends tracking a touch when the user finishes dragging on the `ColorSlider`.
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        
        guard let endTouch = touch else { return }
        updateForTouch(endTouch, touchInside: isTouchInside)
        
        removePreview()
        
        sendActions(for: isTouchInside ? .touchUpInside : .touchUpOutside)
    }
    
    /// Cancels tracking a touch when the user cancels dragging on the `ColorSlider`.
    open override func cancelTracking(with event: UIEvent?) {
        sendActions(for: .touchCancel)
    }
    
    // MARK: -
    ///	Updates the `ColorSlider` color.
    ///	- parameter touch: The touch that triggered the update.
    ///	- parameter touchInside: A boolean value that is `true` if `touch` was inside the frame of the `ColorSlider`.
    fileprivate func updateForTouch(_ touch: UITouch, touchInside: Bool) {
        //        if touchInside {
        // Modify hue at constant brightness
        let locationInView = touch.location(in: self)
        var locationInViewX = max(locationInView.x, 0)
        locationInViewX = min(locationInViewX, frame.width)
        
        // Calculate based on orientation
//        if orientation == .Vertical {
//            hue = 1 - max(0, min(1, (locationInView.y / frame.height)))
//        } else {
//            
//            hue = 1 - max(0, min(1, (locationInView.x / frame.width)))
//        }
//        brightness = 1
        
        //        } else {
        //            // Modify saturation and brightness for the current hue
        //			guard let _superview = superview else { return }
        //			let locationInSuperview = touch.locationInView(_superview)
        //			let horizontalPercent = max(0, min(1, (locationInSuperview.x / _superview.frame.width)))
        //			let verticalPercent = max(0, min(1, (locationInSuperview.y / _superview.frame.height)))
        //
        //			// Calculate based on orientation
        //			if orientation == .Vertical {
        //				saturation = horizontalPercent
        //				brightness = 1 - verticalPercent
        //			} else {
        //				saturation = verticalPercent
        //				brightness = 1 - horizontalPercent
        //			}
        //        }
        
        let xPct = locationInViewX / frame.width
        if (xPct <= 0.5){
            //modifying saturation
            let sat = (xPct * 2) * (originalSaturation - minimumSaturation) + minimumSaturation
            saturation = sat
            brightness = originalBrightness
        }
        else{
            //modifying saturation
            let brt = (((1 - xPct) * 2) * (originalBrightness - minimumBrightness) + minimumBrightness)
            brightness = brt
            saturation = originalSaturation
        }
//        NSLog("Saturation: %f, Brightness: %f, Hue: %f", saturation, brightness, hue)
    }
    
    /// Draws necessary parts of the `ColorSlider`.
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Draw pill shape
        let shortestSide = (bounds.width > bounds.height) ? bounds.height : bounds.width
        drawLayer.cornerRadius = shortestSide / 2.0
        
        // Draw background
        drawLayer.frame = bounds
        if drawLayer.superlayer == nil {
            layer.insertSublayer(drawLayer, at: 0)
        }
    }
    
    // MARK: - Preview
    ///	Shows the color preview.
    ///	- parameter touch: The touch that triggered the update.
    fileprivate func showPreview(_ touch: UITouch) {
        if !previewEnabled { return }
        
        // Initialize preview in proper position, save frame
        updatePreview(touch)
        previewView.transform = minimizedTransformForRect(previewView.frame)
        
        addSubview(previewView)
        UIView.animate(withDuration: previewAnimationDuration, delay: 0, options: .beginFromCurrentState, animations: { () -> Void in
            self.previewView.transform = CGAffineTransform.identity
            }, completion: nil)
    }
    
    ///	Updates the color preview.
    ///	- parameter touch: The touch that triggered the update.
    fileprivate func updatePreview(_ touch: UITouch) {
        if !previewEnabled { return }
        
        // Calculate the position of the preview
        let location = touch.location(in: self)
        var x = orientation == .vertical ? -previewOffset : location.x
        var y = orientation == .vertical ? location.y : -previewOffset
        
        // Restrict preview frame to slider bounds
        if orientation == .vertical {
            y = max(0, location.y - (previewDimension / 2))
            y = min(bounds.height - previewDimension, y)
        } else {
            x = max(0, location.x - (previewDimension / 2))
            x = min(bounds.width - previewDimension, x)
        }
        
        // Update the preview
        let previewFrame = CGRect(x: x, y: y, width: previewDimension, height: previewDimension)
        previewView.frame = previewFrame
        previewView.backgroundColor = color
    }
    
    /// Removes the color preview
    fileprivate func removePreview() {
        if !previewEnabled || previewView.superview == nil { return }
        
        UIView.animate(withDuration: previewAnimationDuration, delay: 0, options: .beginFromCurrentState, animations: { () -> Void in
            self.previewView.transform = self.minimizedTransformForRect(self.previewView.frame)
            }, completion: { (completed: Bool) -> Void in
                self.previewView.removeFromSuperview()
                self.previewView.transform = CGAffineTransform.identity
        })
    }
    
    ///	Calculates the transform from `rect` to the minimized preview view.
    ///	- parameter rect: The actual frame of the preview view.
    ///	- returns: The transform from `rect` to generate the minimized preview view.
    fileprivate func minimizedTransformForRect(_ rect: CGRect) -> CGAffineTransform {
        let minimizedDimension: CGFloat = 5.0
        
        let scale = minimizedDimension / previewDimension
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        
        let tx = orientation == .vertical ? previewOffset : 0
        let ty = orientation == .vertical ? 0 : previewOffset
        let translationTransform = CGAffineTransform(translationX: tx, y: ty)
        
        return scaleTransform.concatenating(translationTransform)
    }
}

extension UIColor {
    var hsba:(h: CGFloat, s: CGFloat,b: CGFloat,a: CGFloat) {
        var hsba:(h: CGFloat, s: CGFloat,b: CGFloat,a: CGFloat) = (0,0,0,0)
        self.getHue(&(hsba.h), saturation: &(hsba.s), brightness: &(hsba.b), alpha: &(hsba.a))
        return hsba
    }
}
