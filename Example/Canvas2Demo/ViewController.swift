//
//  ViewController.swift
//  Canvas2Demo
//
//  Created by ViTiny on 2020/7/31.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Cocoa
import Canvas2

enum LineWidth: Int, CaseIterable {
    case width1
    case width2
    case width3
    
    var width: CGFloat { CGFloat(rawValue) + 1 }
    
    var image: NSImage {
        let size = NSSize(width: 16, height: 16)
        return NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            let y = rect.midY - width / 2
            let points = [CGPoint(x: 0, y: y), CGPoint(x: rect.maxX, y: y)]
            ctx.addLines(between: points)
            ctx.setLineWidth(width)
            ctx.strokePath()
            return true
        }
    }
}

extension CanvasView.PointStyle {
    var image: NSImage {
        let size = CGSize(width: 16, height: 16)
        return NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            switch self {
            case .circle:
                let center = CGPoint(x: rect.midX, y: rect.midY)
                ctx.addArc(
                    center: center,
                    radius: rect.width / 2,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                )
            case .square:
                ctx.addRect(rect)
            }
            ctx.fillPath()
            return true
        }
    }
}

class ViewController: NSViewController {
    
    let loader = ShapeLoader()

    @IBOutlet weak var shapeTableView: NSTableView!
    // Toolbar
    @IBOutlet weak var removeButton: NSButton!
    // Canvas
    @IBOutlet weak var canvasView: CanvasView!
    // Settings
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var lineWidthPopUpButton: NSPopUpButton!
    @IBOutlet weak var pointStylePopUpButton: NSPopUpButton!
    @IBOutlet weak var selectableCheckButton: NSButton!
    @IBOutlet weak var rotationCheckButton: NSButton!
    @IBOutlet weak var magnetCheckButton: NSButton!
    @IBOutlet weak var descriptionCheckButton: NSButton!
    // Polygon
    @IBOutlet weak var polygonCloseCheckButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { _ in self.saveItems() }
        
        shapeTableView.delegate = self
        shapeTableView.dataSource = self
        shapeTableView.doubleAction = #selector(makeShape(_:))
        
        canvasView.backgroundColor = .white
        canvasView.delegate = self
        canvasView.dataSource = self
        
        colorWell.color = canvasView.strokeColor
        
        lineWidthPopUpButton.imageScaling = .scaleAxesIndependently
        lineWidthPopUpButton.imagePosition = .imageOnly
        lineWidthPopUpButton.removeAllItems()
        for lineWidth in LineWidth.allCases {
            lineWidthPopUpButton.addItem(withTitle: lineWidth.width.description)
            lineWidthPopUpButton.lastItem?.image = lineWidth.image
        }
        
        pointStylePopUpButton.imagePosition = .imageOnly
        pointStylePopUpButton.removeAllItems()
        for style in CanvasView.PointStyle.allCases {
            pointStylePopUpButton.addItem(withTitle: style.description)
            pointStylePopUpButton.lastItem?.image = style.image
        }
        
        updateUI()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        do {
            let size = canvasView.bounds.size
            let items = try loader.load(canvasSize: size)
            canvasView.addItems(items)
        } catch {
            showErrorAlert(error, icon: #imageLiteral(resourceName: "Failure"))
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        if event.modifierFlags.contains(.shift) {
            canvasView.lock()
        } else {
            canvasView.unlock()
        }
    }
    
    func saveItems() {
        do {
            let items = canvasView.items
            let size = canvasView.bounds.size
            try loader.save(items, canvasSize: size)
        } catch {
            showErrorAlert(error, icon: #imageLiteral(resourceName: "Failure"))
        }
    }
    
    func showErrorAlert(_ error: Error, icon: NSImage) {
        if let window = view.window {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = error.localizedDescription
            alert.icon = icon
            alert.beginSheetModal(for: window)
        }
    }
    
    func updateUI() {
        removeButton.isEnabled = !canvasView.selectedItems.isEmpty
        selectableCheckButton.state = canvasView.isSelectable ? .on : .off
        rotationCheckButton.state = canvasView.isRotationEnabled ? .on : .off
        magnetCheckButton.state = canvasView.isMagnetEnabled ? .on : .off
        descriptionCheckButton.state = canvasView.showsItemDescription ? .on : .off
        colorWell.color = canvasView.singleSelection?.strokeColor ?? canvasView.strokeColor
        
        let width = canvasView.singleSelection?.lineWidth ?? canvasView.lineWidth
        lineWidthPopUpButton.selectItem(at: LineWidth.allCases.firstIndex(where: { $0.width == width }) ?? -1)
        
        if let polygon = canvasView.singleSelection as? PolygonShape {
            polygonCloseCheckButton.state = polygon.isClosed ? .on : .off
            polygonCloseCheckButton.isHidden = false
        } else {
            polygonCloseCheckButton.isHidden = true
        }
    }
    
    // MARK: - UI Actions
    
    @objc func makeShape(_ sender: NSTableView) {
        guard sender.selectedRow != -1 else { return }
        let shape = ShapeList.allCases[sender.selectedRow]
        canvasView.startSession(shape.shapeType())
        sender.deselectAll(nil)
        updateUI()
    }
    
    @IBAction func cursorButtonAction(_ sender: Any) {
        canvasView.finishSession()
        canvasView.deselectAllItems()
    }
    
    @IBAction func removeButtonAction(_ sender: Any) {
        canvasView.removeSelectedItems()
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        saveItems()
    }
    
    @IBAction func colorWellAction(_ sender: NSColorWell) {
        let color = sender.color
        canvasView.strokeColor = color
        canvasView.itemOfCurrentSession?.strokeColor = color
        canvasView.selectedItems.forEach { $0.strokeColor = color }
    }
    
    @IBAction func lineWidthPopUpButtonAction(_ sender: NSPopUpButton) {
        let lineWidth = LineWidth.allCases[sender.indexOfSelectedItem]
        canvasView.lineWidth = lineWidth.width
        canvasView.itemOfCurrentSession?.lineWidth = lineWidth.width
        canvasView.selectedItems.forEach { $0.lineWidth = lineWidth.width }
    }
    
    @IBAction func pointStylePopUpButtonAction(_ sender: NSPopUpButton) {
        if let style = CanvasView.PointStyle(rawValue: sender.indexOfSelectedItem) {
            canvasView.pointStyle = style
        }
    }
    
    @IBAction func selectableSwitchAction(_ sender: NSButton) {
        canvasView.isSelectable = sender.state == .on
    }
    
    @IBAction func rotationSwitchAction(_ sender: NSButton) {
        canvasView.isRotationEnabled = sender.state == .on
    }
    
    @IBAction func magnetSwitchAction(_ sender: NSButton) {
        canvasView.isMagnetEnabled = sender.state == .on
    }
    
    @IBAction func descriptionCheckButtonAction(_ sender: NSButton) {
        canvasView.showsItemDescription = sender.state == .on
    }
    
    @IBAction func polygonCloseCheckButtonAction(_ sender: NSButton) {
        if let polygon = (canvasView.singleSelection ?? canvasView.itemOfCurrentSession) as? PolygonShape {
            polygon.isClosed = sender.state == .on
        }
    }
    
}

extension ViewController: CanvasViewDelegate {
    
    func canvasView(_ canvasView: CanvasView, sessionDidFinish item: Shape) {
        updateUI()
    }
    
    func canvasView(_ canvasView: CanvasView, didCancelSession item: Shape) {
        updateUI()
    }
    
    func canvasView(_ canvasView: CanvasView, didSelect items: [Shape]) {
        updateUI()
    }
    
    func canvasView(_ canvasView: CanvasView, didDeselect items: [Shape]) {
        updateUI()
    }
    
}

extension ViewController: CanvasViewDataSource {
    
    func undoActionName(
        _ canvasView: CanvasView,
        for action: CanvasView.UndoAction,
        relatedTo items: [Shape]
    ) -> String? {
        switch action {
        case .add:    return "Add \(items)"
        case .remove: return "Remove \(items)"
        case .move:   return "Move \(items)"
        case .edit:   return "Edit \(items[0])"
        case .anchor: return "Anchor \(items[0])"
        case .rotate: return "Rotate \(items[0])"
        }
    }
    
    func description(_ canvasView: CanvasView, for item: Shape) -> String? {
        guard !item.pushContinuously else { return nil }
        return """
        Type     : \(item)
        Selected : \(item.isSelected)
        """
    }
    
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int { ShapeList.allCases.count }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: .shapeCell, owner: nil)
        if let cellView = view as? NSTableCellView {
            let shape = ShapeList.allCases[row]
            cellView.textField?.stringValue = "\(shape)"
        }
        return view
    }
    
}

extension NSUserInterfaceItemIdentifier {
    static let shapeCell = NSUserInterfaceItemIdentifier("ShapeCell")
}
