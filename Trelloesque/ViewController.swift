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
            let lastRowIndex = focus?.0 === tableView ? tableView.numberOfRowsInSection(0) - 1 : tableView.numberOfRowsInSection(0)
            let indexPath = tableView.indexPathForRowAtPoint(localPoint) ?? NSIndexPath(forRow: lastRowIndex, inSection: 0)
            return (tableView, indexPath)
        }
        
        return nil
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
            cell.alpha = 0.0
            cell.contentView.alpha = 0.0
        } else {
            cell.alpha = 1.0
            cell.contentView.alpha = 1.0
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
        func cancelAction() {
            gr.enabled = false
            gr.enabled = true
        }
        
        let location = gr.locationInView(scrollView)
        switch gr.state {
        case .Began:
            guard let (tableView, indexPath) = convertPointToIndexPath(location) else { cancelAction(); return }
            guard tableView.cellForRowAtIndexPath(indexPath) != nil else { cancelAction(); return }
            
            if tableView === tableView1 {
                element = array1.removeAtIndex(indexPath.row)
            } else if tableView === tableView2 {
                element = array2.removeAtIndex(indexPath.row)
            } else {
                element = array3.removeAtIndex(indexPath.row)
            }
            
            // Make a snapshot of the cell
            let cell = tableView.cellForRowAtIndexPath(indexPath)!
            offset = gr.locationInView(cell)
            
            let snapshot = cell.snapshotViewAfterScreenUpdates(true)
            snapshot.frame = scrollView.convertRect(cell.frame, fromView: cell.superview)
            scrollView.addSubview(snapshot)
            self.snapshot = snapshot
            
            focus = (tableView, indexPath)
            
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        case .Changed:
            guard let focus = focus else { cancelAction(); return }
            
            var offsetLocation = location
            offsetLocation.x -= offset!.x
            offsetLocation.y -= offset!.y
            snapshot!.frame.origin = offsetLocation
            
            guard let (tableView, indexPath) = convertPointToIndexPath(location) else { return }
            
            if tableView === focus.0 {
                // Simply move row
                let oldIndexPath = focus.1
                self.focus = (tableView, indexPath)
                tableView.moveRowAtIndexPath(oldIndexPath, toIndexPath: indexPath)
            } else {
                // Remove row in previous table view, add row in current table view
                let (oldTableView, oldIndexPath) = focus
                self.focus = (tableView, indexPath)
                oldTableView.deleteRowsAtIndexPaths([oldIndexPath], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        case .Ended, .Failed, .Cancelled:
            guard let _ = focus else { return }
            
            if let (tableView, indexPath) = convertPointToIndexPath(location) ?? focus {
                self.focus = nil
                if tableView === tableView1 {
                    array1.insert(element!, atIndex: indexPath.row)
                } else if tableView === tableView2 {
                    array2.insert(element!, atIndex: indexPath.row)
                } else {
                    array3.insert(element!, atIndex: indexPath.row)
                }
                element = nil
                self.snapshot?.removeFromSuperview()
                self.snapshot = nil
                
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        default:
            break
        }
    }
    
}

