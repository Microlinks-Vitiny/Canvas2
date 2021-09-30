//
//  Shape.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/20.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Cocoa

extension Shape {

    public enum PointDescriptor: Codable {
        case indexPath(item: Int, section: Int)
        case fixed(x: CGFloat, y: CGFloat)
        
        enum CodingKeys: String, CodingKey {
            case indexPath
            case fixed
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .indexPath(let item, let section):
                try container.encode(IndexPath(item: item, section: section), forKey: .indexPath)
            case .fixed(let x, let y):
                try container.encode(CGPoint(x: x, y: y), forKey: .fixed)
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let key = container.allKeys.first else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: container.codingPath,
                                          debugDescription: "Unabled to decode \(type(of: self)).")
                )
            }
            switch key {
            case .indexPath:
                let indexPath = try container.decode(IndexPath.self, forKey: key)
                self = .indexPath(item: indexPath.item, section: indexPath.section)
            case .fixed:
                let point = try container.decode(CGPoint.self, forKey: key)
                self = .fixed(x: point.x, y: point.y)
            }
        }
    }
    
    public struct PointRelation {
        public var indexPath: IndexPath
        public var x: CGFloat
        public var y: CGFloat
        
        public init(indexPath: IndexPath, x: CGFloat, y: CGFloat) {
            self.indexPath = indexPath
            self.x = x
            self.y = y
        }
    }
    
    public struct Color: Codable {
        public var red: CGFloat
        public var green: CGFloat
        public var blue: CGFloat
        public var alpha: CGFloat
        
        public static func from(_ color: NSColor) -> Color {
            guard let ciColor = CIColor(color: color) else {
                return .init(red: 0, green: 0, blue: 0, alpha: 1)
            }
            return Color(red: ciColor.red,
                         green: ciColor.green,
                         blue: ciColor.blue,
                         alpha: ciColor.alpha)
        }
        
        public var nsColor: NSColor {
            NSColor(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
}

open class Shape: NSObject, Codable {
    
    open private(set) var structure: [Drawable] = []
    open private(set) var body: [Drawable] = []
    open var bodyPath: CGPath? { body.compactMap { $0 as? CGPathProvider }.cgPath() }
    
    open private(set) var layout = Layout()
    open private(set) var rotationAngle: CGFloat = 0
    open private(set) var rotationAnchor: PointDescriptor = .indexPath(item: 0, section: 0)
    open var strokeColor: NSColor = .black {
        didSet { update() }
    }
    open var fillColor: NSColor = .black {
        didSet { update() }
    }
    open var lineWidth: CGFloat = 1 {
        didSet { update() }
    }
    
    open subscript(_ section: Int) -> [CGPoint] { layout[section] }
    open subscript(_ indexPath: IndexPath) -> CGPoint { layout[indexPath] }
    
    open var rotationCenter: CGPoint? {
        guard canFinish else { return nil }
        return getPoint(with: rotationAnchor)
    }
    
    open var endIndexPath: IndexPath? {
        guard !layout.points.isEmpty else { return nil }
        let lastSection = layout.points.count - 1
        return IndexPath(item: layout[lastSection].count - 1, section: lastSection)
    }
    
    // MARK: - Encoding / Decoding-related
    /// Default = -1.
    open private(set) var identifier: Int = -1
    private var userInfo: Data?
    
    // MARK: - Rules
    open var supportsAuxTool: Bool { true }
    open internal(set) var isSelected: Bool = false
    open var pushContinuously: Bool { false }
    open var shouldPushToNextSection: Bool { false }
    open var canFinish: Bool { true }
    open var shouldFinish: Bool { false }
    open private(set) var isFinished: Bool = false
    var updateHandler: (() -> Void)?
    
    // MARK: -
    
    public required override init() {
        super.init()
    }
    
    // MARK: - Main Methods
    
    open func getPoint(with descriptor: PointDescriptor) -> CGPoint {
        switch descriptor {
        case let .indexPath(item, section):
            return self[IndexPath(item: item, section: section)]
        case let .fixed(x, y):
            return CGPoint(x: x, y: y)
        }
    }
    
    open func pointRelations() -> [IndexPath: [PointRelation]] { [:] }
    
    // MARK: -
    
    open func isLocked(at indexPath: IndexPath) -> Bool {
        false
    }
    
    open func updateStructure() -> [Drawable] {
        layout.reduce([Drawable]()) { lines, points in
            let path = ShapePath(method: .defaultDash(width: lineWidth), color: strokeColor) {
                $0.addLines(between: points)
            }
            return lines + [path]
        }
    }
    
    open func updateBody() -> [Drawable] {
        layout.reduce([Drawable]()) { lines, points in
            let path = ShapePath(method: .stroke(lineWidth), color: strokeColor) {
                $0.addLines(between: points)
            }
            return lines + [path]
        }
    }
    
    /// Updates `body` and `structure` and tells the canvas view to redraw.
    open func update() {
        structure = updateStructure()
        if canFinish {
            body = updateBody()
        }
        updateHandler?()
    }
    
    /// Update your variables for later use in `updateStructure()` or `updateBody()` if needed.
    open func layoutDidUpdate() {
        
    }
    
    // MARK: - Edit
    
    open func push(_ point: CGPoint) {
        guard !isFinished && (!shouldFinish || pushContinuously) else { return }
        if shouldPushToNextSection {
            layout.pushToNextSection(point)
        } else {
            layout.push(point)
        }
        layoutDidUpdate()
        update()
    }
    
    func pushToNextSection(_ point: CGPoint) {
        layout.pushToNextSection(point)
    }
    
    open func update(_ point: CGPoint, at indexPath: IndexPath) {
        let oldPoint = layout[indexPath]
        layout[indexPath] = point
        if let rotationCenter = rotationCenter {
            let offset = Line(
                from: oldPoint.rotated(origin: rotationCenter, angle: -rotationAngle),
                to: point.rotated(origin: rotationCenter, angle: -rotationAngle)
            ).offset
            
            if canFinish, let relations = pointRelations()[indexPath] {
                for relation in relations {
                    let dx = relation.x * offset.x
                    let dy = relation.y * offset.y
                    let point = layout[relation.indexPath]
                        .rotated(origin: rotationCenter, angle: -rotationAngle)
                        .applying(.init(translationX: dx, y: dy))
                        .rotated(origin: rotationCenter, angle: rotationAngle)
                    layout[relation.indexPath] = point
                }
            }
        }
        layoutDidUpdate()
        update()
    }
    
    open func updateLast(_ point: CGPoint) {
        guard let indexPath = endIndexPath else { return }
        update(point, at: indexPath)
    }
    
    open func translate(_ offset: Offset) {
        guard canFinish else { return }
        if case .fixed(let x, let y) = rotationAnchor {
            rotationAnchor = .fixed(x: x + offset.x, y: y + offset.y)
        }
        for (i, points) in layout.enumerated() {
            for (j, point) in points.enumerated() {
                let indexPath = IndexPath(item: j, section: i)
                let newPoint = point.applying(.init(translationX: offset.x, y: offset.y))
                layout[indexPath] = newPoint
            }
        }
        layoutDidUpdate()
        update()
    }
    
    open func scale(x mx: CGFloat, y my: CGFloat) {
        if case .fixed(let x, let y) = rotationAnchor {
            setAnchor(at: .fixed(x: x * mx, y: y * my))
        }
        layout.forEach { indexPath, point, _ in
            let newPoint = point
                .applying(.init(scaleX: mx, y: my))
            if newPoint != layout[indexPath] {
                update(newPoint, at: indexPath)
            }
        }
        layoutDidUpdate()
        update()
    }
    
    open func setAnchor(at anchor: PointDescriptor) {
        guard canFinish else { return }
        rotationAnchor = anchor
        update()
    }
    
    open func rotate(_ angle: CGFloat) {
        guard let rotationCenter = rotationCenter else { return }
        for (i, points) in layout.enumerated() {
            for (j, point) in points.enumerated() {
                let indexPath = IndexPath(item: j, section: i)
                let newPoint = point.rotated(origin: rotationCenter, angle: angle - rotationAngle)
                layout[indexPath] = newPoint
            }
        }
        rotationAngle = angle
        layoutDidUpdate()
        update()
    }
    
    open func markAsFinished() {
        guard canFinish else { return }
        isFinished = true
        update()
    }
    
    // MARK: - Drawing
    
    open func draw(with rect: CGRect, in ctx: CGContext) {
        if !isFinished {
            structure.forEach { $0.draw(in: ctx) }
        }
        body.forEach { $0.draw(in: ctx) }
    }
    
    // MARK: - Selection
    
    open func hitTest(_ location: CGPoint, pointRange: CGFloat) -> IndexPath? {
        var result: IndexPath?

        for (i, points) in layout.reversed().enumerated() {
            for (j, point) in points.reversed().enumerated() {
                if point.contains(location, in: pointRange) {
                    let item = points.count - 1 - j
                    let section = layout.points.count - 1 - i
                    result = IndexPath(item: item, section: section)
                    break
                }
            }
        }
        
        return result
    }
    
    open func hitTest(_ location: CGPoint, bodyRange: CGFloat) -> Bool {
        guard let path = bodyPath else { return false }
        let sPath = path.copy(strokingWithWidth: bodyRange * 2,
                              lineCap: .round,
                              lineJoin: .round,
                              miterLimit: 0)
        return sPath.contains(location)
    }
    
    open func selectTest(_ rect: CGRect) -> Bool {
        layout.contains { points in rect.canSelect(points, isClosed: false) }
    }
    
    // MARK: - Codable
    
    public enum CodingKeys: String, CodingKey {
        case layout
        case rotationAngle
        case rotationAnchor
        case strokeColor
        case fillColor
        case lineWidth
        case identifier
        case userInfo
    }

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        guard isFinished else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath,
                                      debugDescription: "Must be finised.")
            )
        }
        try container.encode(layout, forKey: .layout)
        try container.encode(rotationAngle, forKey: .rotationAngle)
        try container.encode(rotationAnchor, forKey: .rotationAnchor)
        try container.encode(Color.from(strokeColor), forKey: .strokeColor)
        try container.encode(Color.from(fillColor), forKey: .fillColor)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(identifier, forKey: .identifier)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let _strokeColor = try container.decode(Color.self, forKey: .strokeColor)
        let _fillColor = try container.decode(Color.self, forKey: .fillColor)
        layout = try container.decode(Layout.self, forKey: .layout)
        rotationAngle = try container.decode(CGFloat.self, forKey: .rotationAngle)
        rotationAnchor = try container.decode(PointDescriptor.self, forKey: .rotationAnchor)
        strokeColor = _strokeColor.nsColor
        fillColor = _fillColor.nsColor
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        identifier = try container.decode(Int.self, forKey: .identifier)
        userInfo = try container.decodeIfPresent(Data.self, forKey: .userInfo)
        super.init()
        markAsFinished()
        layoutDidUpdate()
        update()
    }
    
    open func apply(userInfo: Data) {
        
    }
    
    func convert(to type: Shape.Type) -> Shape {
        let shape = type.init()
        shape.rotationAngle = rotationAngle
        shape.rotationAnchor = rotationAnchor
        shape.strokeColor = strokeColor
        shape.fillColor = fillColor
        shape.lineWidth = lineWidth
        shape.isSelected = isSelected
        shape.isFinished = isFinished
        shape.layout = layout
        shape.layoutDidUpdate()
        shape.update()
        if let info = userInfo {
            shape.userInfo = info
            shape.apply(userInfo: info)
        }
        return shape
    }
    
    open override func copy() -> Any {
        guard isFinished else { fatalError("Copying un-finished shape.") }
        return convert(to: Self.self)
    }
    
}
