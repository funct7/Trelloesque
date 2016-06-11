//
//  ViewController.swift
//  Trelloesque
//
//  Created by Joshua Park on 16.06.11..
//  Copyright © 2016 Monetor. All rights reserved.
//

import UIKit

struct ViewTag {
    static let Left = 10
    static let Center = 11
    static let Right = 12
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var tableView1: UITableView!
    @IBOutlet weak var tableView2: UITableView!
    @IBOutlet weak var tableView3: UITableView!
    var focus: (UITableView, NSIndexPath)?
    var element: String?
    var snapshot: UIView?
    var offset: CGPoint?
    
    var array1 = ["Left-1", "Left-2", "Left-3"]
    var array2 = ["Center-1", "Center-2", "Center-3"]
    var array3 = ["Right-1", "Right-2", "Right-3"]
    
    var longPressGR: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        
        scrollView.addGestureRecognizer(longPressGR)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func convertPointToIndexPath(point: CGPoint) -> (UITableView, NSIndexPath)? {
        if let tableView = [tableView1, tableView2, tableView3].filter({ $0.frame.contains(point) }).first {
            let localPoint = scrollView.convertPoint(point, toView: tableView)
            let lastRowIndex = focus == nil ? tableView.numberOfRowsInSection(0) : tableView.numberOfRowsInSection(0) - 1
            let indexPath = tableView.indexPathForRowAtPoint(localPoint) ?? NSIndexPath(forRow: lastRowIndex, inSection: 0)
            return (tableView, indexPath)
        }
        
        return nil
    }
    
    func addEmptyCellToTableView(tableView: UITableView, atIndexPath indexPath: NSIndexPath) {
        focus = (tableView, indexPath)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Table view
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int!
        switch tableView.tag {
        case ViewTag.Left: count = array1.count
        case ViewTag.Center: count = array2.count
        case ViewTag.Right: count = array3.count
        default: fatalError()
        }
        return focus?.0 === tableView ? count + 1 : count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        if let (tv, ip) = focus where tv === tableView && ip == indexPath {
            cell.contentView.backgroundColor = UIColor.whiteColor()
            cell.textLabel!.text = "EMPTY"
        } else {
            switch tableView.tag {
            case ViewTag.Left: cell.textLabel!.text = array1[indexPath.row]
            case ViewTag.Center: cell.textLabel!.text = array2[indexPath.row]
            case ViewTag.Right: cell.textLabel!.text = array3[indexPath.row]
            default: fatalError()
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: Gesture recognizer
    
    func longPressAction(gr: UILongPressGestureRecognizer) {
        let location = gr.locationInView(scrollView)
        switch gr.state {
        case .Began:
            if let (tableView, indexPath) = convertPointToIndexPath(location) {
                if tableView === tableView1 {
                    element = array1.removeAtIndex(indexPath.row)
                } else if tableView === tableView2 {
                    element = array2.removeAtIndex(indexPath.row)
                } else {
                    element = array3.removeAtIndex(indexPath.row)
                }
                
                // Make a snapshot of the cell
                let cell = tableView.cellForRowAtIndexPath(indexPath)!
                snapshot = cell.snapshotViewAfterScreenUpdates(true)
                snapshot!.frame = scrollView.convertRect(cell.frame, fromView: cell.superview)
                offset = gr.locationInView(cell)
                scrollView.addSubview(snapshot!)
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                addEmptyCellToTableView(tableView, atIndexPath: indexPath)
            }
        case .Changed:
            var offsetLocation = location
            offsetLocation.x -= offset!.x
            offsetLocation.y -= offset!.y
            snapshot!.frame.origin = offsetLocation
            
            if let (tableView, indexPath) = convertPointToIndexPath(location) {
                if tableView === focus!.0 {
                    // Simply move row
                    let oldIndexPath = focus!.1
                    focus = (tableView, indexPath)
                    tableView.moveRowAtIndexPath(oldIndexPath, toIndexPath: indexPath)
                } else {
                    // Remove row in previous table view, add row in current table view
                    let (oldTableView, oldIndexPath) = focus!
                    focus = (tableView, indexPath)
                    oldTableView.deleteRowsAtIndexPaths([oldIndexPath], withRowAnimation: .Automatic)
                    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        case .Ended, .Failed, .Cancelled:
            if let (tableView, indexPath) = convertPointToIndexPath(location) {
                focus = nil
                if tableView === tableView1 {
                    array1.insert(element!, atIndex: indexPath.row)
                } else if tableView === tableView2 {
                    array2.insert(element!, atIndex: indexPath.row)
                } else {
                    array3.insert(element!, atIndex: indexPath.row)
                }
                element = nil
                snapshot!.removeFromSuperview()
                snapshot = nil
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        default:
            break
        }
    }
    
}

