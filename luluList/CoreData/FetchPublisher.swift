import Foundation
import CoreData
import Combine
import UIKit

class FetchPublisher<A, B>: NSObject, NSFetchedResultsControllerDelegate, ObservableObject where A: NSFetchRequestResult {
	
    let publisherPassThrough: PassthroughSubject<[A], Error>
    var controller: NSFetchedResultsController<A>!
	var testMode: Bool
	var converter: (A) -> B?
    
    public var publisher: AnyPublisher<[B], Never> {
        self.publisherPassThrough
			.replaceError(with: [])
			.map{$0.compactMap(self.converter)}
			.eraseToAnyPublisher()
    }

	init(_ fetchRequest: NSFetchRequest<A>, context: NSManagedObjectContext, converter: @escaping (A) -> B?, testMode: Bool = false) {
		self.publisherPassThrough = PassthroughSubject<[A], Error>()
		self.testMode = testMode
		self.converter = converter
        super.init()
		guard !testMode else { return }
		controller = fetchController(fetchRequest, context: context)
        controller.delegate = self
    }
    
	func start() {
		guard !testMode else {
			self.publisherPassThrough.send([])
			return
		}
        do {
            try controller.performFetch()
            self.publisherPassThrough.send(controller.fetchedObjects ?? [])
        } catch {
            self.publisherPassThrough.send(completion: .failure(error))
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.publisherPassThrough.send(controller.fetchedObjects as? [A] ?? [])
    }
	
	func fetchController(_ request: NSFetchRequest<A>, context: NSManagedObjectContext) -> NSFetchedResultsController<A> {
		NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
	}
}

