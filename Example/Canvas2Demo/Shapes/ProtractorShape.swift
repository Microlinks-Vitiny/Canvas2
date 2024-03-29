//
//  ProtractorShape.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/29.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Cocoa
import Canvas2

public class ProtractorShape: Shape, Magnetizable {
    
    public private(set) var arc: Arc?
    public override var identifier: Int { 4 }
    public override var canFinish: Bool { layout.first?.count == 3 }
    public override var shouldFinish: Bool { canFinish }
    
    public init(arc: Arc) {
        super.init()
        self.arc = arc
        push(arc.center.extended(length: arc.radius, angle: arc.startAngle))
        push(arc.center)
        push(arc.center.extended(length: arc.radius, angle: arc.endAngle))
        markAsFinished()
    }
    
    public required init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public override func push(_ point: CGPoint) {
        guard !canFinish else { return }
        super.push(point)
    }
    
    public override func layoutDidUpdate() {
        super.layoutDidUpdate()
        if canFinish {
            let center = layout[0][1]
            let v1 = layout[0][0]
            let v2 = layout[0][2]
            let line1 = Line(from: center, to: v1)
            let line2 = Line(from: center, to: v2)
            let radius = max(line1.distance, line2.distance)
            arc = Arc.vertex(center, point1: v1, point2: v2, radius: radius)
        }
    }
    
    public override func updateBody() -> [Drawable] {
        guard let arc = arc else { return [] }
        
        let v1 = arc.center.extended(length: arc.radius, angle: arc.startAngle)
        let v2 = arc.center.extended(length: arc.radius, angle: arc.endAngle)
        let step: CGFloat = .pi / 180 * 2
        let short = min(7, arc.radius)
        let long = min(15, arc.radius)
        let angleStride = stride(from: 0, through: arc.angle, by: step)
        return [
            ShapePath(method: .stroke(lineWidth), color: strokeColor) { path in
                path.addArc(arc)
                path.addLines(between: [arc.center, v1])
                path.addLines(between: [arc.center, v2])
                for (i, angle) in angleStride.enumerated() {
                    let startAngle = arc.clockwise ? arc.endAngle : arc.startAngle
                    let len: CGFloat = i.isMultiple(of: 5) ? long : short
                    let p1 = arc.center.extended(length: arc.radius, angle: startAngle + angle)
                    let p2 = arc.center.extended(length: arc.radius - len, angle: startAngle + angle)
                    path.addLines(between: [p1, p2])
                }
            },
        ]
    }
    
    public override func selectTest(_ rect: CGRect) -> Bool {
        guard let arc = arc else { return false }
        return rect.canSelect(arc)
    }
    
}
