import SwiftUI
import CoreData
import ComposableArchitecture
import Combine

@Reducer
struct GarmentList {
    @ObservableState
    struct State: Equatable {
        
		var items: IdentifiedArrayOf<Garment> = []
        enum sort: String {
            case alpha = "Alpha"
            case date = "Date Created" }
        var sortedItems: [Garment] {  self.items.sorted(by: { first, second in
            selection == .alpha
            ? first.name < second.name
            : first.created > second.created
        }) }
        var selection: sort = .alpha
        
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
		case removeClip(UUID)
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
				return .run { send in
					try garments.delete(uuid)
				}
				.concatenate(with: .send(.removeClip(uuid), animation: .default))
				
            case .onAppear:
				print("On Appear Started")
                return .run { _ in
					garments.start()
                }
                
			case .onDisappear:
				return .cancel(id: Cancel.publisher)
				
			case .removeClip(let uuid):
				state.items.remove(id: uuid)
				return .none
                
			case .task:
				print("Task Started")
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
                // Catch-all
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
        @Binding var selection: GarmentList.State.sort
        var body: some View {
            Picker("Selection", selection: $selection) {
                Text(GarmentList.State.sort.alpha.rawValue).tag(GarmentList.State.sort.alpha)
                Text(GarmentList.State.sort.date.rawValue).tag(GarmentList.State.sort.date)
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
	previews = true
	try? ["Mini Skirt", "Jeans", "Trainers", "Pants", "Shorts", "Shirt", "Blouse"]
		.forEach(GarmentCD.create)
	return GarmentListView()
}
