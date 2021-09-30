//
//  Polygon.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/23.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Foundation
import Canvas2

class PolygonShape: Shape, Magnetizable {
    
    override var identifier: Int { 2 }
    override var canFinish: Bool {
        let cnt = layout.first?.count ?? 0
        return isClosed ? cnt > 2 : cnt > 1
    }
    
    var isClosed: Bool = true {
        didSet { update() }
    }
    
    private(set) var lines: [Line] = []
    
    required init() {
        super.init()
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = try JSONEncoder().encode(isClosed)
        try container.encode(data, forKey: .userInfo)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func apply(userInfo: Data) {
        if let isClosed = try? JSONDecoder().decode(Bool.self, from: userInfo) {
            self.isClosed = isClosed
        }
    }
    
    public override func isLocked(at indexPath: IndexPath) -> Bool {
        true
    }
    
    override func update() {
        super.update()
        if canFinish {
            let points = layout[0]
            let range = 0..<(points.endIndex - (isClosed ? 0 : 1))
            lines.removeAll()
            for i in range {
                let j = (i + 1) % points.count
                let line = Line(from: points[i], to: points[j])
                lines.append(line)
            }
        }
    }
    
    override func updateBody() -> [Drawable] {
        guard isClosed && canFinish, let points = layout.first else { return super.updateBody() }
        
        var body: [Drawable] = []
        
        body.append(ShapePath(method: .stroke(lineWidth), color: strokeColor) { path in
            path.addLines(between: points)
            if isFinished {
                path.closeSubpath()
            }
        })
        
        if !isFinished, let indexPath = endIndexPath {
            let line = Line(from: layout[indexPath], to: layout[0][0])
            body.append(ShapePath(method: .defaultDash(width: lineWidth), color: strokeColor) { path in
                path.addLine(line)
            })
            body.append(ShapePath(method: .fill, color: fillColor, make: { path in
                path.addArrow(body: 0, head: 6, angle: line.angle, at: line.mid)
            }))
        }
        
        return body
    }
    
    override func selectTest(_ rect: CGRect) -> Bool {
        lines.contains(where: rect.canSelect(_:))
    }
    
}
