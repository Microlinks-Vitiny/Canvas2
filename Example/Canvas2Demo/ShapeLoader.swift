//
//  ShapeLoader.swift
//  Canvas2Demo
//
//  Created by ViTiny on 2020/8/5.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Foundation
import Canvas2

class ShapeLoader {
    
    private let itemsKey = "canvas.items"
    private let widthKey = "canvas.width"
    private let heightKey = "canvas.height"
    
    func load(canvasSize: CGSize) throws -> [Shape] {
        let defaults = UserDefaults.standard
        guard let data = defaults.value(forKey: itemsKey) as? Data,
              let width = defaults.value(forKey: widthKey) as? CGFloat,
              let height = defaults.value(forKey: heightKey) as? CGFloat else { return [] }
        let decoder = ShapeDecoder<ShapeList>()
        let shapes = try decoder.decode([Shape].self, from: data)
        let mx = canvasSize.width / width
        let my = canvasSize.height / height
        shapes.forEach { $0.scale(x: mx, y: my) }
        return shapes.compactMap(decoder.convert(_:))
    }
    
    func save(_ shapes: [Shape], canvasSize: CGSize) throws {
        let defaults = UserDefaults.standard
        let data = try ShapeEncoder().encode(shapes)
        defaults.setValue(data, forKey: itemsKey)
        defaults.setValue(canvasSize.width, forKey: widthKey)
        defaults.setValue(canvasSize.height, forKey: heightKey)
    }
    
}
