//
//  Ruler.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/23.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Foundation
import Canvas2

public final class RulerShape: Shape, Magnetizable {
    
    private var line: Line?
    
    public override var identifier: Int { 0 }
    public override var canFinish: Bool { layout.first?.count == 2 }
    public override var shouldFinish: Bool { canFinish }
    
    public init(line: Line) {
        super.init()
        self.line = line
        push(line.from)
        push(line.to)
        markAsFinished()
    }
    
    public required init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public override func isLocked(at indexPath: IndexPath) -> Bool {
        true
    }
    
    public override func push(_ point: CGPoint) {
        guard !canFinish else { return }
        super.push(point)
    }
    
    public override func layoutDidUpdate() {
        super.layoutDidUpdate()
        if canFinish {
            line = Line(from: layout[0][0], to: layout[0][1])
        }
    }
    
    public override func updateStructure() -> [Drawable] { [] }
    
}
