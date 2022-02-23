import Cocoa
import Foundation
import SwiftUI

func animateStatusBar(statusItem: NSStatusItem) {
  let imageView = statusItem.button

  if let layer = imageView?.layer {
    layer.position = CGPoint(x: layer.frame.midX, y: layer.frame.midY)
    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

    NSAnimationContext.current.allowsImplicitAnimation = true
    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
    rotateAnimation.byValue = 2 * CGFloat.pi * 1000
    rotateAnimation.duration = 3000
    CATransaction.begin()
    layer.add(rotateAnimation, forKey: "rotate")
    CATransaction.commit()
  }
}
