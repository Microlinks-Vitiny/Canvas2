//
//  ShapeDecoder.swift
//  Canvas2
//
//  Created by ViTiny on 2020/8/5.
//

import Foundation

public protocol ShapeTypeConvertible: RawRepresentable {
    var identifier: Int { get }
    init?(identifier: Int)
    func shapeType() -> Shape.Type
}

public enum ShapeDecoderError: Error {
    case undefinedIdentifier
}

public class ShapeDecoder<T: ShapeTypeConvertible>: JSONDecoder {
    
    public func convert(_ shape: Shape) -> Shape? {
        guard let converter = T(identifier: shape.identifier) else { return nil }
        return shape.convert(to: converter.shapeType())
    }
    
}
