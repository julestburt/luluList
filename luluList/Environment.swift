import UIKit
import Combine

var previewInMemory = false
let coredata = CoreData(inMemory: previewInMemory)

var Current = Environment(
	date: { Date() },
    coreData: coredata,
	garments: FetchPublisher(GarmentCD.fetch, context: coredata.context, converter: Garment.init)
)

struct Environment {
	let date: ()-> Date
    var coreData: CoreData
	let garments: FetchPublisher<GarmentCD, Garment>
}
