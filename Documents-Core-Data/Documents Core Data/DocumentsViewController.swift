

import UIKit
import CoreData

class DocumentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    @IBOutlet weak var documentsTableView: UITableView!
    let dateFormatter = DateFormatter()
    var documents = [Document]()
    enum scope {
        case All
        case Name
        case Content
    }
    
    var selectedDocumentScope = scope.All
    
    var filteredDocuments = [Document]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Documents"

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Documents"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.searchController = searchController
        
        searchController.searchBar.scopeButtonTitles = ["All", "Name", "Content"]
        searchController.searchBar.delegate = self
        

    }
    
    // MARK: - Private instance methods
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func updateSearch(for searchControler: UISearchController) {
        fetchDocuments(searchText: searchController.searchBar.text ?? " ")
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredDocuments = documents.filter({( document : Document) -> Bool in
            return (document.name?.lowercased().contains(searchText.lowercased()))!
        })
        
        documentsTableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredDocuments.count
        }
        
        return documents.count
    }


    
    override func viewWillAppear(_ animated: Bool) {
        fetchDocuments(searchText: "")
        documentsTableView.reloadData()
    }
    
    func alertNotifyUser(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
            (alertAction) -> Void in
            print("OK selected")
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func fetchDocuments(searchText: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)] // order results by document name ascending
        
        do {
//            switch (scope).self {
//            case .All:
//                fetchRequest.predicate = NSPredicate(format: "name contains[c] %@ OR content contains[c] %@", searchText, searchText)
//            case .Name:
//                fetchRequest.predicate = NSPredicate(format: "name contains[c] %@", searchText)
//            case .Content:
//                fetchRequest.predicate = NSPredicate(format: "content contains[c] %@", searchText)
//            }
//            

            
            
            documents = try managedContext.fetch(fetchRequest)
            
            documentsTableView.reloadData()
            
        } catch {
            alertNotifyUser(message: "Fetch for documents could not be performed.")
            return
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        if(selectedScope == 1){
            selectedDocumentScope = scope.All
        }
        if(selectedScope == 2){
            selectedDocumentScope = scope.Name
        }
        if(selectedScope == 3){
            selectedDocumentScope = scope.Content
        }
        
        
        fetchDocuments(searchText: searchController.searchBar.text ?? " ")
    }
    
    func deleteDocument(at indexPath: IndexPath) {
        let document = documents[indexPath.row]
        
        if let managedObjectContext = document.managedObjectContext {
            managedObjectContext.delete(document)
            
            do {
                try managedObjectContext.save()
                self.documents.remove(at: indexPath.row)
                documentsTableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                alertNotifyUser(message: "Delete failed.")
                documentsTableView.reloadData()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
   // func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
   //     return documents.count
   // }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "documentCell", for: indexPath)
//
//        if let cell = cell as? DocumentTableViewCell {
//            let document = documents[indexPath.row]
//            cell.nameLabel.text = document.name
//            cell.sizeLabel.text = String(document.size) + " bytes"
//
//            if let modifiedDate = document.modifiedDate {
//                cell.modifiedLabel.text = dateFormatter.string(from: modifiedDate)
//            } else {
//                cell.modifiedLabel.text = "unknown"
//            }
//        }
//
//        return cell
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "documentCell", for: indexPath) as! DocumentTableViewCell
        
        let document: Document
        if isFiltering() {
            document = filteredDocuments[indexPath.row]
        } else {
            document = documents[indexPath.row]
        }
        cell.nameLabel!.text = document.name
        cell.sizeLabel!.text = String(document.size) + " bytes"
        
        if let modifiedDate = document.modifiedDate {
                            cell.modifiedLabel.text = dateFormatter.string(from: modifiedDate)
                        } else {
                            cell.modifiedLabel.text = "unknown"
                        }
        
        return cell
    }
    
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DocumentViewController,
           let segueIdentifier = segue.identifier, segueIdentifier == "existingDocument",
           let row = documentsTableView.indexPathForSelectedRow?.row {
                destination.document = documents[row]
        }
    }
    
    // There are two approaches to implementing deletion of table view cells.  Both are provided below.
    
    // Approach 1: using editing style
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteDocument(at: indexPath)
        }
    }
    
    /*
    // Approach 2: using editing actions
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") {
            action, index in
            self.deleteDocument(at: indexPath)  // self is required because inside of closure
        }
        
        return [delete]
    }
    */
 
    
    

}



