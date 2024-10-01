import Foundation
import ComposableArchitecture
import CoreData
import Combine

struct Garments {
	var fetch: () -> AnyPublisher<[Garment], Never>
	var start: () -> Void
	var delete: (UUID) throws -> Void
	var create: (String) throws -> Void
	var eraseAll: () throws -> Void
}

extension Garments: DependencyKey {
	enum GarmentError: Error { case failDelete, failCreate, failEraseAll }

	static var liveValue = Self(
		fetch: { Current.garments.publisher },
		start: { Current.garments.start() },
		delete: { uuid in
			let context = Current.coreData.context
			let garments = GarmentCD.fetch
			garments.predicate = NSPredicate.init(format: "id == %@", uuid.uuidString as CVarArg)
			guard let garmentForDelete = try context.fetch(garments).first else { throw GarmentError.failDelete }
			Current.coreData.context.delete(garmentForDelete)
			Current.coreData.save(context)
		},
		create: { name in
			guard !name.isEmpty else { throw GarmentError.failCreate }
			let context = Current.coreData.context
			guard let entity = NSEntityDescription.entity(forEntityName: "GarmentCD", in: context),
				  let item = NSManagedObject(entity: entity, insertInto: context) as? GarmentCD else { throw GarmentError.failCreate}
			item.id = UUID()
			item.name = name
			item.created = Date()
			Current.coreData.save(context)
		},
		eraseAll: {
			let context = Current.coreData.context
			let garmentsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "GarmentCD")
			guard let foundGarments = try context.fetch(garmentsFetch) as? [GarmentCD] else { throw GarmentError.failEraseAll }
			foundGarments.forEach(Current.coreData.context.delete)
			Current.coreData.save(context)
		}
	)
}

extension DependencyValues {
	var garments: Garments {
		get { self[Garments.self] }
		set { self[Garments.self] = newValue }
	}
}

