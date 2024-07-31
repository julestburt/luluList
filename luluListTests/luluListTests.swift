import XCTest
import ComposableArchitecture
import Combine
@testable import llList

@MainActor
final class llListTests: XCTestCase {

    func testGarmentList() async throws {
		
		Current.coreData = CoreData.preview
		
		let store = TestStore(initialState: GarmentList.State()) {
			GarmentList()
		} withDependencies: {
			$0.garments.fetch = { Just([Garment]()).eraseToAnyPublisher() }
		}
		
        XCTAssert(store.state.items.count == 0, "Items count not zero")
		
		let samples = ["Mini Skirt", "Jeans", "Trainers", "Pants", "Shorts", "Shirt", "Blouse"]
		for name in samples {
			do {
				try GarmentCD.create(name)
			} catch let error {
				print("failure")
				print((error as NSError).description)
			}
		}

		
    }
}
