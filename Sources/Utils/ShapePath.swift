//
//  ShapePath.swift
//  Canvas2
//
//  Created by ViTiny on 2020/7/31.
//

import AppKit

public class ShapePath: Drawable, CGPathProvider {
    public enum Method: Equatable {
        case stroke(CGFloat)
        case dash(CGFloat, CGFloat, [CGFloat])
        case fill
        
        public static func defaultDash(width: CGFloat = 1) -> Method {
            let dv = width * 2
            return Method.dash(width, dv, [dv, dv])
        }
    }
    
    public var cgPath: CGPath
    public var color: NSColor
    public var method: Method
    
    public init(path: CGPath, method: Method, color: NSColor) {
        self.cgPath = path
        self.method = method
        self.color = color
    }
    
    public init(method: Method, color: NSColor, make: (CGMutablePath) -> Void) {
        let mPath = CGMutablePath()
        self.cgPath = mPath
        self.method = method
        self.color = color
        make(mPath)
    }
    
    public func draw(in ctx: CGContext) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        
        ctx.addPath(cgPath)
        
        switch method {
        case .dash(let w, let p, let ls):
            ctx.setLineDash(phase: p, lengths: ls); fallthrough
        case .stroke(let w):
            ctx.setLineWidth(w)
            ctx.setMiterLimit(w / 2)
            ctx.setStrokeColor(color.cgColor)
            ctx.strokePath()
        default:
            ctx.setFillColor(color.cgColor)
            ctx.fillPath()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case pathElements
        case colorData
        case method
    }
    
}
