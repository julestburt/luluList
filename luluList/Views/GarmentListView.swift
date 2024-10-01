import SwiftUI
import CoreData
import ComposableArchitecture
import Combine

@Reducer
struct GarmentList {
    @ObservableState
    struct State: Equatable {
		var items: IdentifiedArrayOf<Garment> = []
		var selection: SortMethod = .alpha

		enum SortMethod: String {
			case alpha = "Alpha"
			case date = "Date Created"
		}
		var sortedItems: [Garment] {
			self.items.sorted(by: { first, second in
				switch selection {
				case .alpha: first.name < second.name
				case .date: first.created > second.created
				}
			})
		}
        
        @Presents public var destination: Destination.State?
        var cancellable: AnyCancellable?
    }
    
    @Reducer(state: .equatable)
    public enum Destination {
        case add(AddGarment)
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case addItem
        case delete(UUID)
        case onAppear
        case onDisappear
		case remove(UUID)
		case restore(Garment, Int)
        case task
        case updateItems([Garment])
    }
    
    private enum Cancel { case publisher }
    
    @Dependency(\.garments) var garments
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
			switch action {
				
			case .addItem:
				state.destination = .add(AddGarment.State(name: ""))
				return .none
				
			case .delete(let uuid):
				guard let index = state.items.index(id: uuid),
					  let item = state.items[id: uuid] else { return .none }
				return 
					.concatenate(
					.send(.remove(uuid), animation: .default),
					.run { send in
						do {
							try garments.delete(uuid)
						} catch {
							await send(.restore(item, index), animation: .default)
						}
					}
				)

            case .onAppear:
                return .run { _ in
					garments.start()
                }
                
			case .onDisappear:
				return .cancel(id: Cancel.publisher)
				
			case .remove(let uuid):
				state.items.remove(id: uuid)
				return .none
				
			case .restore(let item, let offset):
				state.items.insert(item, at: offset)
				return .none
                
			case .task:
				return .publisher {
					garments.fetch()
						.receive(on: DispatchQueue.main)
						.map(Action.updateItems)
				}
				.cancellable(id: Cancel.publisher, cancelInFlight: true)
				
            case .updateItems(let garments):
				for garment in garments {
					state.items.append(garment)
				}
                return .none
                
            case .destination, .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct GarmentListView: View {
    @Bindable var store: StoreOf<GarmentList> = Store(initialState: GarmentList.State(), reducer: { GarmentList() })

    var body: some View {
        NavigationView {
            VStack {
                SegmentedControlView(selection: $store.selection)
                    .padding(.all, 8)
                Form {
                    ForEach(store.sortedItems) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(item.name)")
                                .font(.headline)
                            Text("\(item.created, formatter: itemFormatter)")
                                .font(.caption)
                        }
                        .swipeActions {
                            Button {
								store.send(.delete(item.id), animation: .default)
                            } label: {
                                Label(
                                    title: { Text("Delete") },
                                    icon: { Image(systemName: "trash") }
                                )
                            }
                            .tint(Color.red.opacity(0.6))
                        }
                    }
                }
                Spacer()
            }
			.navigationTitle("List")
			.navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button{
                        store.send(.addItem)
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
        .task { store.send(.task) }
        .onAppear{ store.send(.onAppear) }
        .onDisappear { store.send(.onDisappear) }
        .sheet(item: $store.scope(state: \.destination?.add, action: \.destination.add)) { store in
            AddGarmentView(store: store)
        }
    }
    
    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    struct SegmentedControlView: View {
        @Binding var selection: GarmentList.State.SortMethod
        var body: some View {
            Picker("Selection", selection: $selection) {
                Text(GarmentList.State.SortMethod.alpha.rawValue).tag(GarmentList.State.SortMethod.alpha)
                Text(GarmentList.State.SortMethod.date.rawValue).tag(GarmentList.State.SortMethod.date)
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
	previewInMemory = true
	try? GarmentCD.createSamples()
	return GarmentListView()
}
