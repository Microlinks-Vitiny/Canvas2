//
//  CanvasView+Drawing.swift
//  
//
//  Created by ViTiny on 2020/10/9.
//

import AppKit

extension CanvasView {
    
    func drawMagnetPoints(for item: Shape, in ctx: CGContext) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        for mItem in items.compactMap({ $0 as? Magnetizable }) {
            for magnet in mItem.magnets() where mItem != item {
                let point = mItem.getPoint(with: magnet)
                ctx.addCrosshair(center: point, length: 13, angle: 0)
                ctx.setLineWidth(2)
            }
        }
        ctx.setStrokeColor(highlightColor.cgColor)
        ctx.strokePath()
    }
    
    private func descriptionDrawingInfo(for description: NSAttributedString, margin: CGFloat, at point: CGPoint) -> (CGRect, CGPoint) {
        let origin = point
            .applying(.init(translationX: margin * 2, y: margin * 2))
        var textRect = CGRect(origin: origin, size: description.size())
            .insetBy(dx: -margin, dy: -margin)
        
        // X
        let maxX = bounds.maxX - margin
        if textRect.maxX > maxX {
            textRect.origin.x = point.x - (description.size().width + margin * 3)
            textRect.origin.x = min(textRect.origin.x, maxX - description.size().width)
        } else if textRect.minX < margin {
            textRect.origin.x = margin
        }
        // Y
        let maxY = bounds.maxY - margin
        if textRect.maxY > maxY {
            textRect.origin.y = point.y - (description.size().height + margin * 3)
            textRect.origin.y = min(textRect.origin.y, maxY - description.size().height)
        } else if textRect.minY < margin {
            textRect.origin.y = margin
        }
        
        return (textRect, CGPoint(x: textRect.minX + margin, y: textRect.minY + margin))
    }
    
    func drawDescription(for item: Shape, drawsPoint: Bool, isHighlighted: Bool, in ctx: CGContext) {
        guard let description = dataSource?.description?(self, for: item) else { return }
        
        guard let origin: CGPoint = {
            let offset = descriptionOffsets[item] ?? .fixed(x: 0, y: 0)
            switch offset {
            case let .fixed(x: x, y: y):
                guard let center = item.center() else { return nil }
                return center.applying(.init(translationX: x, y: y))
            case let .indexPath(item: i, section: s):
                return item[s][i]
            }
        }() else { return }
        
        defer { ctx.restoreGState() }
        ctx.saveGState()
        
        // ===== Point =====
        if drawsPoint {
            drawPoint(origin, pointStyle: pointStyle, rotation: 0, isHighlighted: isHighlighted, in: ctx)
            ctx.addCircle(Circle(center: origin, radius: selectionRange / 2))
            ctx.setFillColor(.black)
            ctx.fillPath()
        }
        
        // ===== Description =====
        let string = NSAttributedString(string: description, attributes: [.font: descriptionFont])
        let margin = CGFloat(selectionRange)
        let (textRect, textPoint) = descriptionDrawingInfo(for: string, margin: margin, at: origin)
        let cr = descriptionCornerRadius
        let path = CGPath(roundedRect: textRect, cornerWidth: cr, cornerHeight: cr, transform: nil)
        // Background
        ctx.addPath(path)
        ctx.setFillColor(descriptionBackgroundColor.cgColor)
        ctx.fillPath()
        // Border
        ctx.addPath(path)
        ctx.setStrokeColor(descriptionBorderColor.cgColor)
        ctx.strokePath()
        // Description
        string.draw(at: textPoint)
    }
    
    func drawSelector(with rect: CGRect, in ctx: CGContext) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        // Background
        ctx.setFillColor(selectorFillColor.cgColor)
        ctx.addRect(rect)
        ctx.fillPath()
        // Border
        ctx.setStrokeColor(selectorBorderColor.cgColor)
        ctx.addRect(rect)
        ctx.strokePath()
    }
    
    func drawPoint(
        _ point: CGPoint,
        pointStyle: PointStyle,
        rotation: CGFloat,
        isHighlighted: Bool,
        in ctx: CGContext
    ) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        
        let len = selectionRange
        let borderColor: CGColor = .black
        let fillColor: CGColor = .white
        // Background
        pointStyle == .circle
            ? ctx.addCircle(Circle(center: point, radius: len))
            : ctx.addSquare(center: point, width: len, rotation: rotation)
        ctx.setFillColor(isHighlighted ? highlightColor.cgColor : fillColor)
        ctx.fillPath()
        // Border
        pointStyle == .circle
            ? ctx.addCircle(Circle(center: point, radius: len))
            : ctx.addSquare(center: point, width: len, rotation: rotation)
        ctx.setStrokeColor(borderColor)
        ctx.strokePath()
    }
    
    func drawPoints(
        for item: Shape,
        pointStyle: PointStyle,
        rotation: CGFloat,
        highlightedIndexPath: IndexPath? = nil,
        in ctx: CGContext
    ) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        item.layout.forEach { indexPath, point, _ in
            if isRotationEnabled, selectedItems.count == 1 {
                if case .indexPath(let item, let section) = item.rotationAnchor,
                    IndexPath(item: item, section: section) == indexPath
                {
                    return
                }
            }
            let highlight = highlightedIndexPath == indexPath
            drawPoint(point, pointStyle: pointStyle, rotation: rotation, isHighlighted: highlight, in: ctx
            )
        }
    }
    
    func drawBoundingBox(for item: Shape, in ctx: CGContext) {
        guard var boundingBox = item.bodyPath?.boundingBoxOfPath else { return }
        defer { ctx.restoreGState() }
        ctx.saveGState()
        boundingBox = boundingBox.insetBy(dx: -selectionRange, dy: -selectionRange)
        boundingBox.origin = CGPoint(x: round(boundingBox.origin.x) + 0.5,
                                     y: round(boundingBox.origin.y) + 0.5)
        boundingBox.size = CGSize(width: round(boundingBox.width),
                                  height: round(boundingBox.height))
        let path = NSBezierPath(roundedRect: boundingBox, xRadius: selectionRange, yRadius: selectionRange)
        var pattern: [CGFloat] = [2, 2]
        path.setLineDash(&pattern, count: pattern.count, phase: 2)
        highlightColor.setStroke()
        path.stroke()
    }
    
    func drawAnchor(for item: Shape, pointStyle: PointStyle, rotation: CGFloat, isHighlighted: Bool, in ctx: CGContext) {
        guard let center = item.rotationCenter else { return }
        defer { ctx.restoreGState() }
        ctx.saveGState()
        drawPoint(center, pointStyle: pointStyle, rotation: rotation, isHighlighted: isHighlighted, in: ctx)
        let len = selectionRange
        ctx.addCrosshair(center: center, length: len, angle: item.rotationAngle)
        ctx.setStrokeColor(.black)
        ctx.strokePath()
    }
    
    func drawRotator(for item: Shape, highlight: Bool, in ctx: CGContext) {
        guard let center = item.rotationCenter else { return }
        defer { ctx.restoreGState() }
        ctx.saveGState()
        let arc = Arc(
            center: center, radius: rotatorRadius,
            from: item.rotationAngle - .pi / 4,
            to: item.rotationAngle + .pi / 4,
            clockwise: false
        )
        let arrowLen: CGFloat = 6
        
        ctx.addArc(arc)
        ctx.setStrokeColor(highlight ? highlightColor.cgColor : .black)
        ctx.strokePath()
        ctx.addArrow(body: 0, head: arrowLen, angle: item.rotationAngle + .pi / 1.4,
                     at: center.extended(length: arc.radius, angle: arc.endAngle))
        ctx.setFillColor(highlight ? highlightColor.cgColor : .black)
        ctx.fillPath()
        ctx.addArrow(body: 0, head: arrowLen, angle: item.rotationAngle - .pi / 1.4,
                     at: center.extended(length: arc.radius, angle: arc.startAngle))
        ctx.fillPath()
    }
    
    func drawAuxTool(for item: Shape, with indexPath: IndexPath, connected: Bool, in ctx: CGContext) {
        guard item[indexPath.section].count > 1 else { return }
        defer { ctx.restoreGState() }
        ctx.saveGState()
        
        let dv = item.lineWidth * 2
        ctx.setLineDash(phase: dv, lengths: [dv, dv])
        ctx.setLineWidth(item.lineWidth)
        
        let aIndexPath = IndexPath(item: indexPath.item + (indexPath.item == 0 ? 1 : -1),
                                   section: indexPath.section)
        let p1 = item[indexPath]
        let p2 = item[aIndexPath]
        let line = Line(from: p1, to: p2)
        let len = line.distance / 2
        let angle = line.angle
        if connected {
            ctx.addLine(line)
        }
        [p1, p2].forEach { point in
            ctx.addLines(between: [
                point.extended(length: len, angle: angle + .pi / 2),
                point.extended(length: len, angle: angle - .pi / 2),
            ])
        }
        ctx.setStrokeColor(item.strokeColor.cgColor)
        ctx.strokePath()
    }
    
}
