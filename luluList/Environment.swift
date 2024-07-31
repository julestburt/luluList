import UIKit
import Combine

// Allows for previews / testing to use in memory
var previews = false
let coredata = CoreData(inMemory: previews)

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
