//
//  ShapeText.swift
//  Canvas2
//
//  Created by ViTiny on 2020/7/31.
//

import AppKit

public class ShapeText: Drawable {
    
    public var string: NSAttributedString
    public var point: CGPoint
    public var angle: CGFloat
    
    public init(string: NSAttributedString, at point: CGPoint, rotation: CGFloat = 0) {
        self.string = string
        self.point = point
        self.angle = rotation
    }
    
    public init(text: String,
                color: NSColor = .black,
                font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize),
                at point: CGPoint,
                rotation: CGFloat = 0)
    {
        self.string = NSAttributedString(string: text, attributes: [.foregroundColor: color, .font: font])
        self.point = point
        self.angle = rotation
    }
    
    public func draw(in ctx: CGContext) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        CGContext.push(ctx) { _ in
            ctx.translateBy(x: point.x, y: point.y)
            ctx.rotate(by: angle)
            string.draw(at: .zero)
        }
    }
    
}
