//
//  ShapeList.swift
//  Canvas2Demo
//
//  Created by ViTiny on 2020/7/31.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Foundation
import Canvas2

extension CanvasView.PointStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .circle: return "Circle"
        case .square: return "Square"
        }
    }
}

enum ShapeList: Int, CaseIterable, CustomStringConvertible, ShapeTypeConvertible {
    
    var identifier: Int { rawValue }
    
    init?(identifier: Int) {
        guard let e = ShapeList(rawValue: identifier) else { return nil }
        self = e
    }
    
    case ruler
    case rect
    case polygon
    case circle
    case goniometer
    case pencil
    
    func shapeType() -> Shape.Type {
        switch self {
        case .ruler:        return RulerShape.self
        case .rect:         return RectangleShape.self
        case .circle:       return CircleShape.self
        case .polygon:      return PolygonShape.self
        case .goniometer:   return ProtractorShape.self
        case .pencil:       return Pencil.self
        }
    }
    
    var description: String {
        switch self {
        case .ruler:        return "Ruler"
        case .rect:         return "Rectangle"
        case .polygon:      return "Polygon"
        case .circle:       return "Circle"
        case .goniometer:   return "Goniometer"
        case .pencil:       return "Pencil"
        }
    }
    
}
