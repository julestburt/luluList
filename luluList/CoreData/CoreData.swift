import CoreData

struct CoreData {
	
    let container: NSPersistentContainer
    private var _mainContext: NSManagedObjectContext { container.viewContext }
    private let _backgroundContext: NSManagedObjectContext
    
    var context:NSManagedObjectContext {
        Thread.isMainThread
        ? _mainContext
        : _backgroundContext
    }
    
	init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "luluList")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
		container.loadPersistentStores { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		}
        container.viewContext.automaticallyMergesChangesFromParent = true
        _backgroundContext = container.newBackgroundContext()
    }
        
    private func saveMain() {
        self.trySave(_mainContext)
    }
    
    func save(_ context: NSManagedObjectContext? = nil) {
        let context = context ?? container.viewContext
        guard context !== container.viewContext else {
            return saveMain()
            
        }
        trySave(context)
    }
    
    private func trySave(_ context:NSManagedObjectContext) {
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    // TODO: Consider handling error conditions
                    fatalError("Failed a Core Data save on: \(context == _mainContext ? "main" : "background") thread")
                }
            }
        }
    }
}
