import XCTest
import ComposableArchitecture
import Combine
@testable import llList

@MainActor
final class AddGarmentTests: XCTestCase {
	
	func testAddGarmentDismiss() async throws {
		
		var testDismissDependencyCalled = false
		let store = TestStore<AddGarment.State, AddGarment.Action>(initialState: AddGarment.State(name: "")) {
			AddGarment()
		} withDependencies: {
			$0.dismiss = .init({
				testDismissDependencyCalled = true
			})
		}

		XCTAssert(store.state.name == "", "Name was not null")
		
		await store.send(.dismiss)
		
		XCTAssert(testDismissDependencyCalled, "Dismiss action failed to call dependency")
	}
	
	func testAddGarment() async throws {
		
		var createDependencyCalled = false
		
		let store = TestStore<AddGarment.State, AddGarment.Action>(initialState: AddGarment.State(name: "New Item")) {
			AddGarment()
		} withDependencies: {
			$0.garments.create = { _ in createDependencyCalled = true }
		}
		
		XCTAssert(store.state.name == "New Item", "Name was 'New Item'")

		await store.send(AddGarment.Action.create)
		
		XCTAssert(createDependencyCalled, "Create Dependency not called")
		
		await store.receive(\.dismiss)
	}

	func testAddGarmentFail() async throws {
		
		enum Add: Error { case fail }
		
		let store = TestStore<AddGarment.State, AddGarment.Action>(initialState: AddGarment.State(name: "")) {
			AddGarment()
		} withDependencies: {
			$0.garments.create = { _ in throw Add.fail }
		}
		
		XCTAssert(store.state.name == "", "Name was not null")
		
		await store.send(AddGarment.Action.create)
				
		await store.receive(\.createError) {
			$0.destination = .alert(.init(title: TextState(verbatim: "Nothing to Save"), message: TextState(verbatim: "Enter a name!"), buttons: [ButtonState<AddGarment.Destination.Alert>.default(TextState(verbatim: "OK"))]))
		}
		
		await store.send(.destination(.presented(.alert(.createFail)))) {
			$0.destination = nil
		}
	}
}
