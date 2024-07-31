import Foundation
import Combine
import ComposableArchitecture
import Dependencies
import CoreData

extension GarmentCD {
	var garment:Garment? {
		let garmentCD = self
		guard let id = garmentCD.id,
			  let name = garmentCD.name,
			  let created = garmentCD.created else { return nil }
		return Garment(id, name: name, created: created)
	}
	
//	static func garment(_ garmentCD: GarmentCD) -> Garment? {
//		guard let id = garmentCD.id,
//			  let name = garmentCD.name,
//			  let created = garmentCD.created else { return nil }
//		return Garment(id, name: name, created: created)
//
//	}
	
	static var fetch: NSFetchRequest<GarmentCD> {
		let request = GarmentCD.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
		return request
	}
}

extension GarmentCD {
	
	static func create(_ name: String) throws {
		let newItem = GarmentCD(context: Current.coreData.context)
		newItem.id = UUID()
		newItem.created = Current.date()
		newItem.name = name
		try? Current.coreData.context.save()
	}
	
	static func reviews(_ viewContext: NSManagedObjectContext) {
		["Mini Skirt", "Jeans", "Trainers", "Pants", "Shorts", "Shirt", "Blouse"]
			.forEach {
				let newItem = GarmentCD(context: viewContext)
				newItem.id = UUID()
				newItem.created = Current.date()
				newItem.name = $0
				do {
					try viewContext.save()
				} catch {
					let nsError = error as NSError
					fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
				}
			}
	}
}
