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
}
