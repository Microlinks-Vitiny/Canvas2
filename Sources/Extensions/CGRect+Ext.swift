//
//  CGRect+Ext.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/20.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Foundation

extension CGRect {
    
    private var corners: [CGPoint] {
        [
            CGPoint(x: minX, y: minY),
            CGPoint(x: maxX, y: minY),
            CGPoint(x: minX, y: maxY),
            CGPoint(x: maxX, y: maxY)
        ]
    }
    
    public func canSelect(_ rect: CGRect) -> Bool {
        intersects(rect) && !rect.contains(self)
    }
    
    public func canSelect(_ points: [CGPoint], isClosed: Bool) -> Bool {
        points.enumerated().contains { i, point in
            guard isClosed || i != points.count - 1 else { return false }
            let j = (i + 1) % points.count
            return canSelect(Line(from: point, to: points[j]))
        }
    }
    
    public func canSelect(_ line: Line) -> Bool {
        contains(line.mid) || [
            Line(from: CGPoint(x: minX, y: minY), to: CGPoint(x: minX, y: maxY)),
            Line(from: CGPoint(x: maxX, y: minY), to: CGPoint(x: maxX, y: maxY)),
            Line(from: CGPoint(x: minX, y: minY), to: CGPoint(x: maxX, y: minY)),
            Line(from: CGPoint(x: minX, y: maxY), to: CGPoint(x: maxX, y: maxY)),
        ].contains { line.collides(with: $0) }
    }
    
    public func canSelect(_ circle: Circle) -> Bool {
        let corners = [CGPoint(x: minX, y: minY), CGPoint(x: maxX, y: minY), CGPoint(x: minX, y: maxY), CGPoint(x: maxX, y: maxY)]
        guard corners.contains(where: { !circle.contains($0) }) else { return false }
        let x = circle.center.x < minX ? minX : (circle.center.x > maxX ? maxX : circle.center.x)
        let y = circle.center.y < minY ? minY : (circle.center.y > maxY ? maxY : circle.center.y)
        let dx = circle.center.x - x
        let dy = circle.center.y - y
        return dx * dx + dy * dy <= circle.radius * circle.radius
    }
    
    public func canSelect(_ arc: Arc) -> Bool {
        let ccount = corners.filter(arc.contains(_:)).count
        
        guard ccount == 0 else { return ccount != corners.count }
        
        let angles: [CGFloat] = [0, .pi / 2, .pi, -.pi / 2]
        let points = angles.filter(arc.contains(_:))
            .map { arc.center.extended(length: arc.radius, angle: $0) }
            
        guard !points.contains(where: contains(_:)) else { return true }
        
        let lines = [
            Line(from: arc.center, to: arc.center.extended(length: arc.radius, angle: arc.startAngle)),
            Line(from: arc.center, to: arc.center.extended(length: arc.radius, angle: arc.endAngle))
        ]
        
        guard !lines.contains(where: canSelect(_:)) else { return true }
        
        let lines2 = points
            .map { Line(from: arc.center, to: $0) }
        
        return lines2.contains(where: canSelect(_:))
    }
    
}
