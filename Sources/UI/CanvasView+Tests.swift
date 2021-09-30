//
//  CanvasView+Tests.swift
//  
//
//  Created by ViTiny on 2020/10/9.
//

import Foundation

extension CanvasView {
    
    func onDescriptionTest(at location: CGPoint) -> Shape? {
        guard let item = singleSelection,
              dataSource?.description?(self, for: item) != nil
        else { return nil }
        
        let point: CGPoint
        let offset = descriptionOffsets[item] ?? .fixed(x: 0, y: 0)
        
        switch offset {
        case let .fixed(x: x, y: y):
            guard let center = item.center() else { return nil }
            point = center.applying(.init(translationX: x, y: y))
        case let .indexPath(item: iItem, section: iSection):
            point = item[iSection][iItem]
        }
        
        return point.contains(location, in: selectionRange) ? item : nil
    }
    
    func descriptionTest(item: Shape, at location: CGPoint) -> Shape.PointDescriptor? {
        guard let center = item.center() else { return nil }
        guard !center.contains(location, in: selectionRange) else {
            return .fixed(x: 0, y: 0)
        }
        let offset = Line(from: center, to: location).offset
        var point: Shape.PointDescriptor = .fixed(x: offset.x, y: offset.y)
        item.layout.forEach { (indexPath, aPoint, stop) in
            guard aPoint.contains(location, in: selectionRange) else { return }
            point = .indexPath(item: indexPath.item, section: indexPath.section)
            stop = true
        }
        return point
    }
    
    func onAnchorTest(at location: CGPoint) -> Shape? {
        guard let item = singleSelection, let center = item.rotationCenter else { return nil }
        return center.contains(location, in: selectionRange) ? item : nil
    }
    
    func anchoringTest(item: Shape, location: CGPoint) -> Shape.PointDescriptor {
        var anchor: Shape.PointDescriptor? = .fixed(x: location.x, y: location.y)
        item.layout.forEach { (indexPath, point, stop) in
            guard point.contains(location, in: selectionRange) else { return }
            anchor = .indexPath(item: indexPath.item, section: indexPath.section)
            stop = true
        }
        return anchor!
    }
    
    func onRotatorTest(at location: CGPoint) -> Shape? {
        guard let item = singleSelection, let center = item.rotationCenter else { return nil }
        let line = Line(from: center, to: location)
        let range = (rotatorRadius - selectionRange)...(rotatorRadius + selectionRange)
        
        guard range.contains(line.distance) else { return nil }
        let start = item.rotationAngle + .pi / 4
        let end = item.rotationAngle - .pi / 4
        let arc = Arc(center: center, radius: range.upperBound, from: start, to: end, clockwise: true)
        return arc.contains(location) ? item : nil
    }
    
    func onPointTest(at location: CGPoint) -> (Shape, IndexPath)? {
        for item in selectedItems.reversed() where !item.pushContinuously {
            if let indexPath = item.hitTest(location, pointRange: selectionRange) {
                return (item, indexPath)
            }
        }
        return nil
    }
    
    func onItemTest(at location: CGPoint) -> Shape? {
        func filter(_ item: Shape) -> Bool {
            item.hitTest(location, bodyRange: selectionRange)
        }
        guard let item = selectedItems.reversed().first(where: filter(_:)) else {
            return items.filter { !$0.isSelected }
                .reversed()
                .first(where: filter(_:))
        }
        return item
    }
    
    func magnetTest(item: Shape, at location: CGPoint) -> (Shape, CGPoint)? {
        for mItem in items.compactMap({ $0 as? Magnetizable }) where mItem != item {
            guard let magnet = mItem.magnet(for: location, range: selectionRange) else { continue }
            let point: CGPoint = mItem.getPoint(with: magnet)
            return (mItem, point)
        }
        return nil
    }
    
}
