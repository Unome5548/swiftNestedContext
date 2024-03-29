import UIKit
import CoreData
import AVFoundation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, VPDAODelegateProtocol, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else{
            return nil
        }
    }()

    lazy var childContext: NSManagedObjectContext? = {
        let childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        childContext.parentContext = self.managedObjectContext
        return childContext
    }()

    //Main NSFetchedResultsController
    var taskController: NSFetchedResultsController?
    //Segment1 NSFetchedResultsController
    var _gospelController: NSFetchedResultsController?
    var gospelController : NSFetchedResultsController {
        get{
            if _gospelController != nil{
                return _gospelController!
            }
            var subtaskRequest = NSFetchRequest(entityName: "Subtasks")
            var segIndex = self.segmentedControl.selectedSegmentIndex
            subtaskRequest.predicate = NSPredicate(format: "task.category.name == %@", "Gospel Principles")
            subtaskRequest.sortDescriptors = [NSSortDescriptor(key: "task.englishTitle", ascending: true), NSSortDescriptor(key: "sortOrder", ascending: true)]

            self._gospelController = NSFetchedResultsController(fetchRequest: subtaskRequest, managedObjectContext:
                self.childContext!, sectionNameKeyPath: "task.englishTitle", cacheName: nil)
            self._gospelController?.delegate = self
            return self._gospelController!
        }
    }
    //Segment2 NSFetchedResultsController
    var _missionaryController: NSFetchedResultsController?
    var missionaryController : NSFetchedResultsController {
        get{
            if _missionaryController != nil{
                return _missionaryController!
            }
            var subtaskRequest = NSFetchRequest(entityName: "Subtasks")
            var segIndex = self.segmentedControl.selectedSegmentIndex
            subtaskRequest.predicate = NSPredicate(format: "task.category.name == %@", "Missionary Tasks")
            subtaskRequest.sortDescriptors = [NSSortDescriptor(key: "task.englishTitle", ascending: true), NSSortDescriptor(key: "sortOrder", ascending: true)]

            self._missionaryController = NSFetchedResultsController(fetchRequest: subtaskRequest, managedObjectContext:
                self.childContext!, sectionNameKeyPath: "task.englishTitle", cacheName: nil)
            self._missionaryController?.delegate = self
            return self._missionaryController!
        }
    }
    //Segment3 NSFetchedResultsController
    var _otherController: NSFetchedResultsController?
    var otherController : NSFetchedResultsController {
        get{
            if _otherController != nil{
                return _otherController!
            }
            var subtaskRequest = NSFetchRequest(entityName: "Subtasks")
            var segIndex = self.segmentedControl.selectedSegmentIndex
            subtaskRequest.predicate = NSPredicate(format: "task.category.name == %@", "Other Vocabulary")
            subtaskRequest.sortDescriptors = [NSSortDescriptor(key: "task.englishTitle", ascending: true), NSSortDescriptor(key: "sortOrder", ascending: true)]

            self._otherController = NSFetchedResultsController(fetchRequest: subtaskRequest, managedObjectContext:
                self.childContext!, sectionNameKeyPath: "task.englishTitle", cacheName: nil)
            self._otherController?.delegate = self
            return self._otherController!
        }
    }

    func reloadData(){
        managedObjectContext!.save(nil)
        childContext!.performBlock{
            self.gospelController.performFetch(nil)
            self.missionaryController.performFetch(nil)
            self.otherController.performFetch(nil)
            self.managedObjectContext!.performBlock{

                if self.segmentedControl.selectedSegmentIndex == 0 {
                    self.taskController = self.gospelController
                }else if self.segmentedControl.selectedSegmentIndex == 1{
                    self.taskController = self.missionaryController
                }else{
                    self.taskController = self.otherController
                }
                self.tableView.reloadData()
            }

        }
    }

    func gotVPStructure() {
        reloadData()
    }

    @IBAction func categoryChanged(sender: AnyObject) {
        if segmentedControl.selectedSegmentIndex == 0 {
            taskController = gospelController
        }else if segmentedControl.selectedSegmentIndex == 1{
            taskController = missionaryController
        }else{
            taskController = otherController
        }
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //Initialize some properites..
        //...
        reloadData()
        taskController = missionaryController
        VPDAO.sharedManager.getVPStructureForDelegate(self, toLocale: toLocale, fromLocale: fromLocale, context: childContext!)
    }


    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return taskController!.sections!.count{
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return taskController!.sections!.numberOfObjects
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60;
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let subtask = taskController!.objectAtIndexPath(indexPath) as? Subtasks{
            if(subtask.isOpen == 1){
                return 40
            }
        }
        return 0;
    }
    var subtasks: Array<Subtasks> = []
    func tappedOnSection(sender: UITapGestureRecognizer)->Void{
        tableView.beginUpdates()
            var sections = self.taskController!.sections! as Array
            var subtasks = sections[sender.view!.tag].objects
            for var i = 0; i < subtasks.count; i+=1{
                var index : NSIndexPath = NSIndexPath(forRow: i, inSection: sender.view!.tag)
                var subtask = subtasks[i] as Subtasks
                if(subtask.isOpen == 1){
                    subtask.isOpen = 0
                }
                else{
                    subtask.isOpen = 1
                }
            }

        tableView.endUpdates()
    }

    func configureCell(cell: UITableViewCell, atIndexPath: NSIndexPath){
        let object = taskController!.objectAtIndexPath(atIndexPath) as Subtasks
        cell.textLabel.text = "    " + object.englishTitle
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController){
        managedObjectContext!.performBlock{
            self.tableView.beginUpdates()
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController){
        managedObjectContext!.performBlock{
            self.tableView.endUpdates()
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        managedObjectContext!.performBlock{
            switch(type){
            case NSFetchedResultsChangeType.Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            default:
                return
            }
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        managedObjectContext!.performBlock{
            switch(type){
            case NSFetchedResultsChangeType.Insert:
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Update:
                if self.tableView.cellForRowAtIndexPath(indexPath!) != nil{
                    self.configureCell(self.tableView.cellForRowAtIndexPath(newIndexPath!)!, atIndexPath: indexPath!)
                }
            case NSFetchedResultsChangeType.Move:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        }
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var header: UITableViewHeaderFooterView
        header = UITableViewHeaderFooterView(reuseIdentifier: "header")

        var sections: Array<NSFetchedResultsSectionInfo> = taskController!.sections as Array<NSFetchedResultsSectionInfo>
        var object = sections[section] as NSFetchedResultsSectionInfo

        var title: UILabel = UILabel()
        title.textColor = UIColor.vpListFontLevel1()
        title.font = UIFont(name: "Times New Roman", size: 25)
        title.text = object.name
        title.setTranslatesAutoresizingMaskIntoConstraints(false)

        header.addConstraint(NSLayoutConstraint(item: title, attribute: .Left, relatedBy: .Equal, toItem: header, attribute: .Left, multiplier: 1.0, constant: 15))
        return header
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      //Giant piece of code that creates the UI for a scroll view page
    }
}
