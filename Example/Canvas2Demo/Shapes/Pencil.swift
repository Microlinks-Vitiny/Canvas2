//
//  Pencil.swift
//  Canvas2Demo
//
//  Created by ViTiny on 2020/8/5.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Foundation
import Canvas2

class Pencil: Shape {
    
    public override var identifier: Int { 5 }
    override var pushContinuously: Bool { true }
    override var canFinish: Bool { !layout.isEmpty }
    override var shouldFinish: Bool { canFinish }
    
    override func updateStructure() -> [Drawable] { [] }
    
}
