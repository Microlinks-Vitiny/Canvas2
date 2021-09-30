//
//  CircleItem.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/23.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Foundation
import Canvas2

public final class CircleShape: Shape, Magnetizable {
    
    public private(set) var circle: Circle?
    public override var identifier: Int { 3 }
    public override var canFinish: Bool { layout.first?.count == 3 }
    public override var shouldFinish: Bool { canFinish }
    
    public init(circle: Circle) {
        super.init()
        let center = circle.center
        let radius = circle.radius
        [
            center.extended(length: radius, angle: 0),
            center.extended(length: radius, angle: .pi / 2),
            center.extended(length: radius, angle: .pi)
        ].forEach { push($0) }
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
            circle = Circle(layout[0][0], layout[0][1], layout[0][2])
        }
    }
    
    public override func updateBody() -> [Drawable] {
        guard let circle = circle else { return [] }
        return [
            ShapePath(method: .stroke(lineWidth), color: strokeColor) { path in
                path.addCircle(circle)
                path.addCrosshair(center: circle.center, length: 10, angle: rotationAngle)
            }
        ]
    }
    
    public override func selectTest(_ rect: CGRect) -> Bool {
        guard let circle = circle else { return false }
        return rect.canSelect(circle) || rect.contains(circle.center)
    }
    
}
