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
    var focus: (UITableView, IndexPath)?
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
    
    func convertPointToIndexPath(point: CGPoint) -> (UITableView, IndexPath)? {
        if let tableView = [tableView1, tableView2, tableView3].filter({ $0.frame.contains(point) }).first {
            let localPoint = scrollView.convert(point, to: tableView)
            let lastRowIndex = focus?.0 === tableView ? tableView.numberOfRows(inSection: 0) - 1 : tableView.numberOfRows(inSection: 0)
            let indexPath = tableView.indexPathForRow(at: localPoint) ?? NSIndexPath(row: lastRowIndex, section: 0) as IndexPath
            return (tableView, indexPath)
        }
        
        return nil
    }
    
    // MARK: - Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int!
        switch tableView.tag {
        case ViewTag.Left: count = array1.count
        case ViewTag.Center: count = array2.count
        case ViewTag.Right: count = array3.count
        default: fatalError()
        }
        return focus?.0 === tableView ? count + 1 : count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        
        if let (tv, ip) = focus, tv === tableView && ip as IndexPath == indexPath {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    // MARK: Gesture recognizer
    
    @objc func longPressAction(gr: UILongPressGestureRecognizer) {
        func cancelAction() {
            gr.isEnabled = false
            gr.isEnabled = true
        }
        
        let location = gr.location(in: scrollView)
        switch gr.state {
        case .began:
            guard let (tableView, indexPath) = convertPointToIndexPath(point: location) else { cancelAction(); return }
            guard tableView.cellForRow(at: indexPath as IndexPath) != nil else { cancelAction(); return }
            
            if tableView === tableView1 {
                element = array1.remove(at: indexPath.row)
            } else if tableView === tableView2 {
                element = array2.remove(at: indexPath.row)
            } else {
                element = array3.remove(at: indexPath.row)
            }
            
            // Make a snapshot of the cell
            let cell = tableView.cellForRow(at: indexPath as IndexPath)!
            offset = gr.location(in: cell)
            
            let snapshot = cell.snapshotView(afterScreenUpdates: true)
            snapshot?.frame = scrollView.convert(cell.frame, from: cell.superview)
            scrollView.addSubview(snapshot!)
            self.snapshot = snapshot
            
            focus = (tableView, indexPath)
            
            tableView.reloadRows(at: [indexPath as IndexPath], with: .fade)
        case .changed:
            guard let focus = focus else { cancelAction(); return }
            
            var offsetLocation = location
            offsetLocation.x -= offset!.x
            offsetLocation.y -= offset!.y
            snapshot!.frame.origin = offsetLocation
            
            guard let (tableView, indexPath) = convertPointToIndexPath(point: location) else { return }
            
            if tableView === focus.0 {
                // Simply move row
                let oldIndexPath = focus.1
                self.focus = (tableView, indexPath)
                tableView.moveRow(at: oldIndexPath as IndexPath, to: indexPath as IndexPath)
            } else {
                // Remove row in previous table view, add row in current table view
                let (oldTableView, oldIndexPath) = focus
                self.focus = (tableView, indexPath)
                oldTableView.deleteRows(at: [oldIndexPath as IndexPath], with: .fade)
                tableView.insertRows(at: [indexPath as IndexPath], with: .fade)
            }
        case .ended, .failed, .cancelled:
            guard let _ = focus else { return }
            
            if let (tableView, indexPath) = convertPointToIndexPath(point: location) ?? focus {
                self.focus = nil
                if tableView === tableView1 {
                    array1.insert(element!, at: indexPath.row)
                } else if tableView === tableView2 {
                    array2.insert(element!, at: indexPath.row)
                } else {
                    array3.insert(element!, at: indexPath.row)
                }
                element = nil
                self.snapshot?.removeFromSuperview()
                self.snapshot = nil
                
                tableView.reloadRows(at: [indexPath as IndexPath], with: .fade)
            }
        default:
            break
        }
    }
    
}

