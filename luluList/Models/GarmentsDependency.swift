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
	static var liveValue = Self(
		fetch: { Current.garments.publisher },
		start: { Current.garments.start() },
		delete: { uuid in
			let context = Current.coreData.context
			let garments = GarmentCD.fetch
			garments.predicate = NSPredicate.init(format: "id == %@", uuid as CVarArg)
			enum GarmentError: Error { case fail }
			guard let garmentForDelete = try context.fetch(garments).first else { throw GarmentError.fail }
			Current.coreData.context.delete(garmentForDelete)
			Current.coreData.save(context)
		},
		create: { name in
			enum GarmentCreate: Error { case fail }
			guard !name.isEmpty else {
				throw GarmentCreate.fail
			}
			let context = Current.coreData.context
			guard let entity = NSEntityDescription.entity(forEntityName: "GarmentCD", in: context),
				  let item = NSManagedObject(entity: entity, insertInto: context) as? GarmentCD else { throw GarmentCreate.fail }
			item.id = UUID()
			item.name = name
			item.created = Date()
			Current.coreData.save(context)
		},
		eraseAll: {
			let context = Current.coreData.context
			let garmentsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "GarmentCD")
			enum GarmentError: Error { case fail }
			guard let foundGarments = try context.fetch(garmentsFetch) as? [GarmentCD] else { throw GarmentError.fail }
			foundGarments.forEach(Current.coreData.context.delete)
			Current.coreData.save(context)
		}
	)
	
//	static var previewValue = Garments(
//		fetch: { Just([Garment(name:"Test Item")]).eraseToAnyPublisher() },
//		start: {},
//		delete: { _ in },
//		create: { _ in },
//		eraseAll: {}
//	)
	
//	static var testValue = Garments(
//		fetch: { Just([Garment.testGarment]).eraseToAnyPublisher() },
//		start: {},
//		delete: { _ in },
//		create: { _ in },
//		eraseAll: {}
//	)
}

extension DependencyValues {
	var garments: Garments {
		get { self[Garments.self] }
		set { self[Garments.self] = newValue }
	}
}

