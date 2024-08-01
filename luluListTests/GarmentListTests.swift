import XCTest
import ComposableArchitecture
import Combine
@testable import llList

struct PublisherFeed<A> {
	let publisherPassThrough: PassthroughSubject<[A], Never>
	public var publisher: AnyPublisher<[A], Never> {
		self.publisherPassThrough
			.eraseToAnyPublisher()
	}
	
	func publishValues(_ values: [A]) {
		publisherPassThrough.send(values)
	}
}

@MainActor
final class GarmentListTests: XCTestCase {

	let testGarments = Garment.testSamples

	func testGarmentListPublisherSetup() async throws {
				
		let store = TestStore<GarmentList.State, GarmentList.Action>(initialState: GarmentList.State()) {
			GarmentList()
		} withDependencies: {
			$0.garments.fetch = { Just([self.testGarments.first!]).eraseToAnyPublisher() }
		}
		
		XCTAssert(store.state.items.count == 0, "Items count not zero")
		
		await store.send(GarmentList.Action.onAppear)
		await store.send(GarmentList.Action.task)
		
		await store.receive(\.updateItems) {
			$0.items = [self.testGarments.first!]
		}
	}
	
	func testGarmentListPublisherFeed() async throws {
		
		let publisherFeed = PublisherFeed(publisherPassThrough: PassthroughSubject<[Garment], Never>())
		
		let store = TestStore<GarmentList.State, GarmentList.Action>(initialState: GarmentList.State()) {
			GarmentList()
		} withDependencies: {
			$0.garments.fetch = { publisherFeed.publisher }
		}
		
		XCTAssert(store.state.items.count == 0, "Items count not zero")
		
		await store.send(GarmentList.Action.onAppear)
		await store.send(GarmentList.Action.task)
		
		publisherFeed.publishValues([self.testGarments.first!])

		await store.receive(\.updateItems) {
			$0.items.append(contentsOf: [self.testGarments.first!])
		}
		
		await store.send(.onDisappear)
    }
	
	func testGarmentListDelete() async throws {
				
		let store = TestStore<GarmentList.State, GarmentList.Action>(initialState: GarmentList.State()) {
			GarmentList()
		} withDependencies: {
			$0.garments.fetch = { Just(self.testGarments).eraseToAnyPublisher() }
		}
		
		XCTAssert(store.state.items.count == 0, "Items count not zero")

		await store.send(GarmentList.Action.onAppear)
		await store.send(GarmentList.Action.task)
		
		await store.receive(\.updateItems) {
			$0.items = IdentifiedArray(uncheckedUniqueElements: self.testGarments)
		}
		
		await store.send(.delete(self.testGarments.first!.id))
		
		await store.receive(\.remove) {
			$0.items.remove(id: self.testGarments.first!.id)
		}

		await store.send(.delete(self.testGarments.last!.id))
		
		await store.receive(\.remove) {
			$0.items.remove(id: self.testGarments.last!.id)
		}
	}
	
	func testGarmentListDeleteFail() async throws {
		
		enum DeleteTest: Error { case fail }
		
		let store = TestStore<GarmentList.State, GarmentList.Action>(initialState: GarmentList.State()) {
			GarmentList()
		} withDependencies: {
			$0.garments.fetch = { Just(self.testGarments).eraseToAnyPublisher() }
			$0.garments.delete = { _ in
				throw DeleteTest.fail
			}
		}
		
		XCTAssert(store.state.items.count == 0, "Items count not zero")
		
		await store.send(GarmentList.Action.onAppear)
		await store.send(GarmentList.Action.task)
		
		await store.receive(\.updateItems) {
			$0.items = IdentifiedArray(uncheckedUniqueElements: self.testGarments)
		}
		
		await store.send(.delete(self.testGarments.first!.id))
		
		let garment = self.testGarments.first!
		let index = store.state.items.index(id: garment.id)!
		
		await store.receive(\.remove) {
			$0.items.remove(id: UUID(0))
		}
		
		await store.receive(\.restore) {
			$0.items.insert(garment, at: index)
		}
	}

	func testGarmentCreateButton() async throws {
		
		let store = TestStore<GarmentList.State, GarmentList.Action>(initialState: GarmentList.State()) {
			GarmentList()
		} withDependencies: {
			$0.garments.fetch = { Just(self.testGarments).eraseToAnyPublisher() }
		}
		
		XCTAssert(store.state.items.count == 0, "Items count not zero")
		
		await store.send(.addItem) {
			$0.destination = .add(.init(name: ""))
		}
	}
}
