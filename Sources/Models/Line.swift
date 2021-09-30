//
//  Line.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/20.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Foundation

public typealias Offset = CGPoint

extension Line {
    public enum IntersectionType {
        case intersect(CGPoint)
        case coincident
        case parallel
    }
}

public struct Line {
    
    public var from: CGPoint
    public var to: CGPoint
    public var dx: CGFloat { to.x  -  from.x }
    public var dy: CGFloat { to.y  -  from.y }
    public var offset: Offset { CGPoint(x: dx, y: dy) }
    public var distance: CGFloat { sqrt(dx * dx + dy * dy) }
    public var angle: CGFloat { atan2(dy, dx) }
    public var mid: CGPoint { CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2) }
    
    public init(from: CGPoint, to: CGPoint) {
        self.from = from
        self.to = to
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        let A = (from.x - point.x) * (from.x - point.x) + (from.y - point.y) * (from.y - point.y)
        let B = (to.x - point.x) * (to.x - point.x) + (to.y - point.y) * (to.y - point.y)
        let C = (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
        return (A + B + 2 * sqrt(A * B) - C < 1)
    }
    
    public func intersection(_ line: Line) -> IntersectionType {
        let EPS: CGFloat = 1e-5
        func EQ(_ x: CGFloat, _ y: CGFloat) -> Bool { return abs(x - y) < EPS }
        let A1 = to.y - from.y
        let B1 = from.x - to.x
        let C1 = to.x * from.y - from.x * to.y
        let A2 = line.to.y - line.from.y
        let B2 = line.from.x - line.to.x
        let C2 = line.to.x * line.from.y - line.from.x * line.to.y
        guard !EQ(A1 * B2, B1 * A2) else {
            return EQ( (A1 + B1) * C2, (A2 + B2) * C1 ) ? .coincident : .parallel
        }
        return .intersect(CGPoint(
            x: (B2 * C1 - B1 * C2) / (A2 * B1 - A1 * B2),
            y: (A1 * C2 - A2 * C1) / (A2 * B1 - A1 * B2)))
    }
    
    public func projection(_ point: CGPoint) -> CGPoint? {
        guard distance != 0 else { return nil }
        let A = from, B = to, C = point
        let AC = CGPoint(x: C.x - A.x, y: C.y - A.y)
        let AB = CGPoint(x: B.x - A.x, y: B.y - A.y)
        let ACAB = AC.x * AB.x + AC.y * AB.y
        let m = ACAB / (distance * distance)
        let AD = CGPoint(x: AB.x * m, y: AB.y * m)
        return CGPoint(x: A.x + AD.x, y: A.y + AD.y)
    }
    
    public func collides(with line: Line) -> Bool {
        let uA = (line.dx * (from.y - line.from.y) - line.dy * (from.x - line.from.x)) /
        (line.dy * dx - line.dx * dy)
        let uB = (dx * (from.y - line.from.y) - dy * (from.x - line.from.x)) /
        (line.dy * dx - line.dx * dy)
        return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1
    }
    
}
