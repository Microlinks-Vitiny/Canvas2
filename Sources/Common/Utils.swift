//
//  Tools.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/22.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import AppKit

public func radiansToDegrees(_ r: CGFloat) -> CGFloat { r / .pi * 180 }

public func degreesToRadians(_ d: CGFloat) -> CGFloat { d * .pi / 180 }

public func calcAngle(_ vertex: CGPoint, _ pointA: CGPoint, _ pointB: CGPoint) -> CGFloat? {
    let len1 = Line(from: vertex, to: pointA).distance
    let len2 = Line(from: vertex, to: pointB).distance
    let len3 = Line(from: pointA, to: pointB).distance
    let a = (len1 * len1 + len2 * len2 - len3 * len3)
    let b = (len1 * len2 * 2.0)
    return b == 0 ? nil : acos(a / b)
}


// MARK: -

public protocol Drawable {
    func draw(in ctx: CGContext)
}

public protocol CGPathProvider {
    var cgPath: CGPath { get }
}

extension Array where Element == CGPathProvider {
    func cgPath() -> CGPath {
        reduce(CGMutablePath()) { path, provider in
            path.addPath(provider.cgPath)
            return path
        }
    }
}

// MARK: - Magnetizable

public protocol Magnetizable: Shape {
    func magnets() -> [Shape.PointDescriptor]
    func magnet(for point: CGPoint, range: CGFloat) -> Shape.PointDescriptor?
}

extension Magnetizable {
    
    public func magnets() -> [Shape.PointDescriptor] {
        var magnets: [Shape.PointDescriptor] = []
        layout.forEach { (indexPath, _, _) in
            magnets += [.indexPath(item: indexPath.item, section: indexPath.section)]
        }
        return magnets
    }
    
    public func magnet(for location: CGPoint, range: CGFloat) -> Shape.PointDescriptor? {
        guard canFinish else { return nil }
        return magnets().first { magnet in
            let point: CGPoint = getPoint(with: magnet)
            return point.contains(location, in: range)
        }
    }
    
}
