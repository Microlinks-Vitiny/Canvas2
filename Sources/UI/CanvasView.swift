//
//  CanvasView.swift
//  Canvas
//
//  Created by ViTiny on 2020/7/21.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Cocoa

extension Shape {
    func center() -> CGPoint? {
        guard let boundingBox = bodyPath?.boundingBox else { return nil }
        return CGPoint(x: boundingBox.midX, y: boundingBox.midY)
    }
}

@objc public protocol CanvasViewDelegate: AnyObject {
    @objc optional func canvasView(_ canvasView: CanvasView, items: [Shape], in selector: CGRect)
    // Drawing Session
    @objc optional func canvasView(_ canvasView: CanvasView, didStartSession item: Shape)
    @objc optional func canvasView(_ canvasView: CanvasView, willFinishSession item: Shape)
    @objc optional func canvasView(_ canvasView: CanvasView, didCancelSession item: Shape)
    @objc optional func canvasView(_ canvasView: CanvasView, didFinishSession item: Shape)
    // Selection
    @objc optional func canvasView(_ canvasView: CanvasView, didSelect items: [Shape])
    @objc optional func canvasView(_ canvasView: CanvasView, didDeselect items: [Shape])
    // Modification
    @objc optional func canvasView(_ canvasView: CanvasView, didEdit item: Shape, indexPath: IndexPath)
    @objc optional func canvasView(_ canvasView: CanvasView, didMove item: Shape)
    @objc optional func canvasView(_ canvasView: CanvasView, didRotate item: Shape)
    @objc optional func canvasView(_ canvasView: CanvasView, didAnchor item: Shape)
}

@objc public protocol CanvasViewDataSource: AnyObject {
    @objc optional func menu(_ canvasView: CanvasView) -> NSMenu?
    @objc optional func itemMenu(_ canvasView: CanvasView, for item: Shape) -> NSMenu?
    
    @objc optional func description(_ canvasView: CanvasView, for item: Shape) -> String?
    
    @objc optional func undoActionName(_ canvasView: CanvasView, for action: CanvasView.UndoAction, relatedTo items: [Shape]) -> String?
}

extension CanvasView {
    
    enum MouseAction {
        case idle
        case down
        case drag
    }
    
    public enum State {
        case idle
        case selecting(CGRect)
        case drawing(Shape)
        
        case onDescription(Shape, CGPoint)
        case movingDescription(Shape, CGPoint)
        
        case onAnchor(Shape, Shape.PointDescriptor)
        case movingAnchor(Shape, Shape.PointDescriptor)
        
        case onRotator(Shape, CGFloat, CGPoint)
        case movingRotator(Shape, CGFloat, CGPoint)
        
        case onItem(Shape, CGPoint, CGPoint)
        case movingItem(Shape, CGPoint, CGPoint)
        
        case onPoint(Shape, IndexPath, CGPoint)
        case movingPoint(Shape, IndexPath, CGPoint)
    }
    
    public struct ItemScalingMask: OptionSet {
        public var rawValue: Int
        
        public init(rawValue: Int) { self.rawValue = rawValue }
        
        public static let width = ItemScalingMask(rawValue: 1 << 0)
        public static let height = ItemScalingMask(rawValue: 1 << 1)
    }
    
    @objc public enum PointStyle: Int, CaseIterable {
        case circle
        case square
    }
    
    @objc public enum UndoAction: Int {
        case add
        case remove
        case move
        case edit
        case anchor
        case rotate
    }
    
}

@objcMembers
public final class CanvasView: NSView {
    
    private var currentSize: CGSize = .zero
    
    private var mouseAction: MouseAction = .idle
    
    public weak var delegate: CanvasViewDelegate?
    
    public weak var dataSource: CanvasViewDataSource?
    
    public private(set) var state: State = .idle
    
    dynamic
    public private(set) var items: [Shape] = []
    
    dynamic
    public private(set) var selectedItems: [Shape] = []
    
    var descriptionOffsets: [Shape: Shape.PointDescriptor] = [:]
    
    // MARK: - Convenience Getters
    
    public var itemOfCurrentSession: Shape? {
        if case .drawing(let item) = state { return item }
        return nil
    }
    
    public var selectionIndexes: IndexSet {
        IndexSet(selectedItems.compactMap(items.firstIndex(of:)))
    }
    
    public var singleItem: Shape? {
        items.count == 1 ? items.first : nil
    }
    
    public var singleSelection: Shape? {
        selectedItems.count == 1 ? selectedItems.first : nil
    }
    
    // MARK: - Settings
    
    var rotatorRadius: CGFloat { selectionRange * 2.5 }
    
    dynamic
    public var isUndoable: Bool = true
    
    dynamic
    public var itemScalingMask: ItemScalingMask = [.width]
    
    dynamic
    public var isLocked: Bool = false
    
    dynamic
    public var backgroundColor: NSColor = .clear
    
    dynamic
    public var selectorBorderColor: NSColor = .lightGray
    
    dynamic
    public var selectorFillColor: NSColor = NSColor(white: 0.5, alpha: 0.5)
    
    dynamic
    public var lineWidth: CGFloat = 1
    
    dynamic
    public var strokeColor: NSColor = .black
    
    dynamic
    public var fillColor: NSColor = .clear
    
    dynamic
    public var highlightColor: NSColor = .selectedMenuItemColor
    
    dynamic
    public var drawsAuxiliaryLine: Bool = true
    
    dynamic
    public var pointStyle: PointStyle = .circle {
        didSet { refresh() }
    }
    
    dynamic
    public var selectionRange: CGFloat = 5 {
        didSet { refresh() }
    }
    
    dynamic
    public var isSelectable: Bool = true {
        didSet { deselectAllItems() }
    }
    
    dynamic
    public var isRotationEnabled: Bool = false {
        didSet { refresh() }
    }
    
    dynamic
    public var isMagnetEnabled: Bool = false {
        didSet { refresh() }
    }
    
    dynamic
    public var showsItemDescription: Bool = false {
        didSet { refresh() }
    }
    
    dynamic
    public var descriptionFont: NSFont = NSFont(name: "Monaco", size: NSFont.systemFontSize)
    ?? NSFont.systemFont(ofSize: NSFont.systemFontSize) {
        didSet { refresh() }
    }
    
    dynamic
    public var descriptionBorderColor: NSColor = .black {
        didSet { refresh() }
    }
    
    dynamic
    public var descriptionBackgroundColor: NSColor = .init(white: 1, alpha: 0.7) {
        didSet { refresh() }
    }
    
    dynamic
    public var descriptionCornerRadius: CGFloat = 5 {
        didSet { refresh() }
    }
    
    // MARK: - Life Cycle
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    public init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    private func commonInit() {
    }
    
    private func multipliers(from fromSize: CGSize, to toSize: CGSize) -> (mx: CGFloat, my: CGFloat)? {
        guard fromSize != .zero && toSize != .zero else { return nil }
        
        let mx = toSize.width / fromSize.width
        let my = toSize.height / fromSize.height
        
        switch itemScalingMask {
        case [.width, .height]: return (mx, my)
        case .width:            return (mx, mx)
        case .height:           return (my, my)
        default:                return nil
        }
    }
    
    public override func layout() {
        super.layout()
        
        if let (mx, my) = multipliers(from: currentSize, to: bounds.size) {
            items.forEach { $0.scale(x: mx, y: my) }
        }
        
        currentSize = bounds.size
    }
    
    // MARK: - Drawing
    
    private func refresh() {
        needsDisplay = true
    }
    
    /// Draws items and descriptions(If `showsDescription` is `true`) only.
    public func drawSnapshot(_ rect: NSRect) {
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.setFillColor(backgroundColor.cgColor)
        ctx.fill(rect)
        ctx.restoreGState()
        
        let sortedItems = items
            .filter({ !selectedItems.contains($0) })
            + selectedItems
        
        for item in sortedItems {
            item.draw(with: rect, in: ctx)
            if showsItemDescription {
                drawDescription(for: item, drawsPoint: false, isHighlighted: false, in: ctx)
            }
        }
        
        if let item = itemOfCurrentSession, item.canFinish {
            item.draw(with: rect, in: ctx)
            if showsItemDescription {
                drawDescription(for: item, drawsPoint: false, isHighlighted: false, in: ctx)
            }
        }
    }
    
    public override func draw(_ rect: NSRect) {
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        ctx.setFillColor(backgroundColor.cgColor)
        ctx.fill(rect)
        ctx.restoreGState()
        
        let sortedItems = items
            .filter({ !selectedItems.contains($0) })
            + selectedItems
        
        for item in sortedItems {
            item.draw(with: rect, in: ctx)
        }
        itemOfCurrentSession?.draw(with: rect, in: ctx)

        switch state {
        case .movingItem: break
        case .drawing(let item) :
            if mouseAction == .drag && drawsAuxiliaryLine && item.supportsAuxTool,
                let indexPath = item.endIndexPath
            {
                drawAuxTool(for: item, with: indexPath, connected: false, in: ctx)
            }
            if isMagnetEnabled {
                drawMagnetPoints(for: item, in: ctx)
            }
        case .movingPoint(let item, let indexPath, _):
            if drawsAuxiliaryLine && item.supportsAuxTool {
                drawAuxTool(for: item, with: indexPath, connected: true, in: ctx)
            }
            if isMagnetEnabled {
                drawMagnetPoints(for: item, in: ctx)
            }
        default:
            for item in sortedItems where item.isSelected {
                if !item.pushContinuously {
                    var markedIndexPath: IndexPath?
                    if case .onPoint(let mItem, let indexPath, _) = state, mItem == item {
                        markedIndexPath = indexPath
                    }
                    drawPoints(for: item, pointStyle: pointStyle,
                               rotation: item.rotationAngle,
                               highlightedIndexPath: markedIndexPath,
                               in: ctx)
                } else {
                    drawBoundingBox(for: item, in: ctx)
                }
                
                if selectedItems.count == 1 {
                    if isRotationEnabled {
                        var highlightAnchor = false
                        var highlightRotator = false
                        switch state {
                        case .onRotator, .movingRotator: highlightRotator = true
                        case .onAnchor, .movingAnchor: highlightAnchor = true
                        default: break
                        }
                        drawAnchor(for: item, pointStyle: pointStyle,
                                   rotation: item.rotationAngle,
                                   isHighlighted: highlightAnchor,
                                   in: ctx)
                        drawRotator(for: item, highlight: highlightRotator, in: ctx)
                    }
                }
            }
        }
        
        if showsItemDescription {
            for item in sortedItems {
                var highlighted: Bool = false
                var drawsPoint = false
                if item.isSelected, selectedItems.count == 1 {
                    drawsPoint = true
                    switch state {
                    case .onDescription, .movingDescription:
                        highlighted = true
                    default:
                        highlighted = false
                    }
                }
                drawDescription(for: item, drawsPoint: drawsPoint, isHighlighted: highlighted, in: ctx)
            }
            if let item = itemOfCurrentSession, item.canFinish {
                drawDescription(for: item, drawsPoint: false, isHighlighted: false, in: ctx)
            }
        }
        
        if case .selecting(let rect) = state {
            drawSelector(with: rect, in: ctx)
        }
    }
    
    // MARK: - Mouse Events
    
    private func lockedPoint(item: Shape, indexPath: IndexPath, location: CGPoint) -> CGPoint? {
        guard item.layout[indexPath.section].count > 1 else { return nil }
        let idx = indexPath.item == 0 ? indexPath.item + 1 : indexPath.item - 1
        let newIndexPath = IndexPath(item: idx, section: indexPath.section)
        let l = Line(from: item[newIndexPath], to: location)
        let m = abs(l.dy / l.dx)
        return m > 1 || m.isNaN
            ? CGPoint(x: l.from.x, y: l.to.y)
            : CGPoint(x: l.to.x, y: l.from.y)
    }
    
    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        mouseAction = .down
        
        switch state {
        case .idle where isSelectable:
            if showsItemDescription, let item = onDescriptionTest(at: location) {
                state = .onDescription(item, location)
            } else if isRotationEnabled, let item = onRotatorTest(at: location) {
                state = .onRotator(item, item.rotationAngle, location)
            } else if isRotationEnabled, let item = onAnchorTest(at: location) {
                state = .onAnchor(item, item.rotationAnchor)
            } else if let (item, indexPath) = onPointTest(at: location) {
                internalSelectItems([item], byExtendingSelection: false)
                state = .onPoint(item, indexPath, item[indexPath])
            } else if let item = onItemTest(at: location) {
                if !selectedItems.contains(item) {
                    internalSelectItems([item], byExtendingSelection: false)
                }
                state = .onItem(item, location, location)
            } else {
                let origin = CGPoint(x: round(location.x) + 0.5, y: round(location.y) + 0.5)
                let rect = CGRect(origin: origin, size: .zero)
                deselectAllItems()
                state = .selecting(rect)
            }
        case .drawing(let item):
            if item.layout.isEmpty {
                delegate?.canvasView?(self, didStartSession: item)
            }
            if item.pushContinuously {
                item.pushToNextSection(location)
            } else {
                if isMagnetEnabled, let (_, magnetPoint) = magnetTest(item: item, at: location) {
                    item.push(magnetPoint)
                } else {
                    item.push(location)
                }
                if item.layout.last?.count == 1 {
                    item.push(location)
                }
            }
            if item.canFinish {
                delegate?.canvasView?(self, willFinishSession: item)
            }
        default:
            break
        }
        
        refresh()
    }
    
    public override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        mouseAction = .drag
        
        switch state {
        case .selecting(let rect):
            let line = Line(from: rect.origin, to: location)
            let size = CGSize(width: round(line.dx), height: round(line.dy))
            let rect = CGRect(origin: rect.origin, size: size)
            selectItems(with: rect)
            state = .selecting(rect)
        case .drawing(let item):
            if item.pushContinuously {
                item.push(location)
            } else {
                if isMagnetEnabled, let (_, magnetPoint) = magnetTest(item: item, at: location) {
                    item.updateLast(magnetPoint)
                } else {
                    item.updateLast(location)
                    
                    if isLocked,
                       let indexPath = item.endIndexPath, item.isLocked(at: indexPath),
                       let newLocation = lockedPoint(item: item, indexPath: indexPath, location: location)
                    {
                        item.updateLast(newLocation)
                    } else {
                        item.updateLast(location)
                    }
                }
            }
            if item.canFinish {
                delegate?.canvasView?(self, willFinishSession: item)
            }
            
        case let .onDescription(item, offset): fallthrough
        case let .movingDescription(item, offset):
            descriptionOffsets[item] = descriptionTest(item: item, at: location)
            state = .movingDescription(item, offset)
            
        case let .onRotator(item, oldAngle, lastPoint): fallthrough
        case let .movingRotator(item, oldAngle, lastPoint):
            guard let center = item.rotationCenter else { break }
            
            let prev = Line(from: center, to: lastPoint).angle
            let curr = Line(from: center, to: location).angle
            let newRotation = item.rotationAngle + (curr - prev)
            item.rotate(newRotation)
            state = .movingRotator(item, oldAngle, location)
            delegate?.canvasView?(self, didRotate: item)
            
        case .onAnchor(let item, let oldAnchor): fallthrough
        case .movingAnchor(let item, let oldAnchor):
            let anchor = anchoringTest(item: item, location: location)
            item.setAnchor(at: anchor)
            state = .movingAnchor(item, oldAnchor)
            delegate?.canvasView?(self, didAnchor: item)
            
        case .onPoint(let item, let indexPath, let initPoint): fallthrough
        case .movingPoint(let item, let indexPath, let initPoint):
            if isMagnetEnabled, let (_, magnetPoint) = magnetTest(item: item, at: location) {
                item.update(magnetPoint, at: indexPath)
            } else {
                if isLocked,
                   item.isLocked(at: indexPath),
                   let newLocation = lockedPoint(item: item, indexPath: indexPath, location: location)
                {
                    item.update(newLocation, at: indexPath)
                } else {
                    item.update(location, at: indexPath)
                }
            }
            state = .movingPoint(item, indexPath, initPoint)
            delegate?.canvasView?(self, didEdit: item, indexPath: indexPath)
            
        case .onItem(let item, let lastLocation, let startLocation): fallthrough
        case .movingItem(let item, let lastLocation, let startLocation):
            let offset = Line(from: lastLocation, to: location).offset
            selectedItems.forEach { $0.translate(offset) }
            state = .movingItem(item, location, startLocation)
            delegate?.canvasView?(self, didMove: item)
            
        default:
            break
        }
        
        refresh()
    }
    
    public override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        mouseAction = .idle
        
        switch state {
        case .selecting(let rect):
            let selector = CGRect(x: rect.minX, y: rect.minY,
                                  width: abs(rect.width),
                                  height: abs(rect.height))
            state = .idle
            delegate?.canvasView?(self, items: selectedItems, in: selector)
        case .drawing(let item):
            if item.shouldFinish && item.canFinish {
                finishSession()
            }
            
        case .onDescription: fallthrough
        case .movingDescription:
            state = .idle
            
        case .onRotator:
            state = .idle
        case let .movingRotator(item, angle, _):
            registerUndoRotateItem(item, rotation: angle)
            state = .idle
            
        case .onAnchor:
            state = .idle
        case let .movingAnchor(item, anchor):
            registerUndoAnchorItem(item, anchor: anchor)
            state = .idle
            
        case .onPoint:
            state = .idle
        case let .movingPoint(item, indexPath, initPoint):
            let offset = Line(from: initPoint, to: location).offset
            registerUndoEditItem(item, offset: offset, at: indexPath, viewSize: currentSize)
            state = .idle
            
        case .onItem(let item, _, _):
            internalSelectItems([item], byExtendingSelection: false)
            state = .idle
        case let .movingItem(item, _, startLocation):
            let offset = Line(from: startLocation, to: location).offset
            registerUndoMoveItems(selectedItems, on: item, offset: offset, viewSize: currentSize)
            state = .idle
            
        default:
            break
        }
        
        refresh()
    }
    
    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        
        guard itemOfCurrentSession == nil else {
            finishSession()
            return
        }
        
        let location = convert(event.locationInWindow, from: nil)
        
        let menu: NSMenu? = {
            guard dataSource?.itemMenu != nil, let item = onItemTest(at: location) else {
                guard dataSource?.menu != nil else { return nil }
                deselectAllItems()
                return dataSource?.menu?(self)
            }
            if !selectedItems.contains(item) {
                internalSelectItems([item], byExtendingSelection: false)
            }
            return dataSource?.itemMenu?(self, for: item)
        }()
        
        if let menu = menu {
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }
    
    // MARK: - Session
    
    @discardableResult
    public func finishSession() -> Shape? {
        guard case .drawing(let item) = state else { return nil }
        addItems([item])
        state = .idle
        if items.contains(item) {
            delegate?.canvasView?(self, didFinishSession: item)
        } else {
            delegate?.canvasView?(self, didCancelSession: item)
        }
        refresh()
        return item
    }
    
    @discardableResult
    public func startSession<T: Shape>(_ type: T.Type) -> T {
        finishSession()
        deselectAllItems()
        let item = type.init()
        item.lineWidth = lineWidth
        item.strokeColor = strokeColor
        item.fillColor = fillColor
        item.updateHandler = { [weak self] in self?.refresh() }
        state = .drawing(item)
        return item
    }
    
    public func lock() {
        isLocked = true
    }
    
    public func unlock() {
        isLocked = false
    }
    
    // MARK: - Add
    
    public func addItems(_ itemsToAdd: [Shape]) {
        let itemsToAdd = itemsToAdd.filter { item in
            item.markAsFinished()
            return item.isFinished
        }
        
        if !itemsToAdd.isEmpty {
            for item in itemsToAdd {
                item.updateHandler = { [weak self] in
                    self?.refresh()
                }
                items.append(item)
            }
            registerUndoAddItems(itemsToAdd)
            refresh()
        }
    }
    
    // MARK:: - Selection
    
    private func internalSelectItems(_ itemsToSelect: [Shape], byExtendingSelection extending: Bool) {
        let selection = extending
            ? selectedItems + itemsToSelect.filter { !selectedItems.contains($0) }
            : itemsToSelect
        let bye = Set(selectedItems).subtracting(selection)
            .reduce([Shape]()) { bye, item in
                item.isSelected = false
                return bye + [item]
            }
        let hi = selection.filter { item in
            guard !item.isSelected else { return false }
            item.isSelected = true
            return true
        }

        selectedItems.removeAll(where: bye.contains)
        if !bye.isEmpty { delegate?.canvasView?(self, didDeselect: bye) }

        selectedItems.append(contentsOf: hi)
        if !hi.isEmpty { delegate?.canvasView?(self, didSelect: hi) }

        refresh()
    }
    
    public func selectItems(_ itemsToSelect: [Shape], byExtendingSelection extending: Bool) {
        let itemsToSelect = itemsToSelect.filter(items.contains)
        internalSelectItems(itemsToSelect, byExtendingSelection: extending)
    }
    
    public func selectItems(at indexes: IndexSet, byExtendingSelection extending: Bool) {
        let itemsToSelect = indexes.map { items[$0] }
        internalSelectItems(itemsToSelect, byExtendingSelection: extending)
    }
    
    public func selectItems(with rect: CGRect) {
        let itemsToSelect = items.filter { $0.selectTest(rect) }
        internalSelectItems(itemsToSelect, byExtendingSelection: false)
    }
    
    public func selectAllItems() {
        internalSelectItems(items, byExtendingSelection: false)
    }
    
    public func deselectItems(_ itemsToDeselect: [Shape]) {
        let itemsToSelect = selectedItems.filter { !itemsToDeselect.contains($0) }
        internalSelectItems(itemsToSelect, byExtendingSelection: false)
    }
    
    public func deselectAllItems() {
        internalSelectItems([], byExtendingSelection: false)
    }
    
    // MARK: - Removal
    
    @discardableResult
    public func removeItems(_ itemsToRemove: [Shape]) -> [Shape] {
        let itemsToRemove = itemsToRemove.filter(items.contains)
        let removeds = itemsToRemove.compactMap { item -> Shape? in
            guard let index = items.firstIndex(of: item)
            else { return nil }
            let item = items.remove(at: index)
            descriptionOffsets[item] = nil
            return item
        }
        deselectItems(removeds)
        registerUndoRemoveItems(removeds, viewSize: currentSize)
        return removeds
    }
    
    @discardableResult
    public func removeItems(at indexes: IndexSet) -> [Shape] {
        let itemsToRemove = indexes.map { items[$0] }
        return removeItems(itemsToRemove)
    }
    
    @discardableResult
    public func removeFirst(_ k: Int) -> [Shape] {
        let itemsToRemove = Array(items[..<k])
        return removeItems(itemsToRemove)
    }
    
    @discardableResult
    public func removeLast(_ k: Int) -> [Shape] {
        let s = items.count - k
        let itemsToRemove = Array(items[s...])
        return removeItems(itemsToRemove)
    }
    
    @discardableResult
    public func removeSelectedItems() -> [Shape] {
        removeItems(selectedItems)
    }
    
    @discardableResult
    public func removeAllItems() -> [Shape] {
        removeItems(items)
    }
    
}

// MARK: - Undo / Redo

extension CanvasView {
    
    func registerUndoAction(name: String?, _ handler: @escaping (CanvasView) -> Void) {
        guard isUndoable else { return }
        undoManager?.registerUndo(withTarget: self, handler: handler)
        if let name = name {
            undoManager?.setActionName(name)
        }
    }
    
    func registerUndoAddItems(_ items: [Shape]) {
        let name = dataSource?.undoActionName?(self, for: .add, relatedTo: items)
        registerUndoAction(name: name) { view in
            view.removeItems(items)
        }
    }
    
    func registerUndoRemoveItems(_ items: [Shape], viewSize: CGSize) {
        let name = dataSource?.undoActionName?(self, for: .remove, relatedTo: items)
        registerUndoAction(name: name) { view in
            guard let (mx, my) = view.multipliers(from: viewSize, to: view.currentSize) else { return }
            items.forEach { $0.scale(x: mx, y: my) }
            view.addItems(items)
        }
    }
    
    func registerUndoMoveItems(_ items: [Shape], on item: Shape, offset: Offset, viewSize: CGSize) {
        let name = dataSource?.undoActionName?(self, for: .move, relatedTo: items)
        registerUndoAction(name: name) { view in
            guard let (mx, my) = view.multipliers(from: viewSize, to: view.currentSize) else { return }
            let offset = Offset(x: -offset.x * mx, y: -offset.y * my)
            items.forEach { $0.translate(offset) }
            view.registerUndoMoveItems(items, on: item, offset: offset, viewSize: view.currentSize)
            view.delegate?.canvasView?(view, didMove: item)
        }
    }
    
    func registerUndoEditItem(_ item: Shape, offset: Offset, at indexPath: IndexPath, viewSize: CGSize) {
        let name = dataSource?.undoActionName?(self, for: .edit, relatedTo: [item])
        registerUndoAction(name: name) { view in
            guard let (mx, my) = view.multipliers(from: viewSize, to: view.currentSize) else { return }
            let offset = Offset(x: -offset.x * mx, y: -offset.y * my)
            let point = item[indexPath]
                .applying(.init(translationX: offset.x, y: offset.y))
            item.update(point, at: indexPath)
            view.registerUndoEditItem(item, offset: offset, at: indexPath, viewSize: view.currentSize)
            view.delegate?.canvasView?(view, didEdit: item, indexPath: indexPath)
        }
    }
    
    func registerUndoAnchorItem(_ item: Shape, anchor: Shape.PointDescriptor) {
        let name = dataSource?.undoActionName?(self, for: .anchor, relatedTo: [item])
        registerUndoAction(name: name) { view in
            let currAnchor = item.rotationAnchor
            item.setAnchor(at: anchor)
            view.registerUndoAnchorItem(item, anchor: currAnchor)
            view.delegate?.canvasView?(view, didAnchor: item)
        }
    }
    
    func registerUndoRotateItem(_ item: Shape, rotation: CGFloat) {
        let name = dataSource?.undoActionName?(self, for: .rotate, relatedTo: [item])
        registerUndoAction(name: name) { view in
            let currRotation = item.rotationAngle
            item.rotate(rotation)
            view.registerUndoRotateItem(item, rotation: currRotation)
            view.delegate?.canvasView?(view, didRotate: item)
        }
    }
    
}
