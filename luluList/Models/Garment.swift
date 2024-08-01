import Foundation
import CoreData

struct Garment: Identifiable, Equatable, Hashable {
	let id: UUID
	let name:String
	let created:Date
	
	init(_ id:UUID = UUID(), name:String, created:Date = Current.date()) {
		self.id = id
		self.name = name
		self.created = created
	}
	
	init?<G: GarmentCD>(_ garmentCD: G) {
		guard let id = garmentCD.id,
			  let name = garmentCD.name,
			  let created = garmentCD.created else { return nil }
		self.id = id
		self.name = name
		self.created = created
		return
	}
	
	static let testSamples: [Garment] = [
		.init(UUID.init(0), name: "Garment 0", created: Date(timeIntervalSince1970: 0)),
		.init(UUID.init(1), name: "Garment 1", created: Date(timeIntervalSince1970: 1)),
		.init(UUID.init(2), name: "Garment 2", created: Date(timeIntervalSince1970: 2)),
		.init(UUID.init(3), name: "Garment 3", created: Date(timeIntervalSince1970: 3)),
		.init(UUID.init(4), name: "Garment 4", created: Date(timeIntervalSince1970: 4))
	]
}
