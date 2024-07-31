import SwiftUI
import ComposableArchitecture

@Reducer
struct AddGarment {
    @ObservableState
    struct State: Equatable {
        var name: String
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case save
        case dismiss
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.garments) var garments
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .save:
                return .run { [name = state.name] send in
                    do {
                        try garments.create(name)
                        await send(.dismiss)
                    } catch {
                        // TODO: Present an alert
                        fatalError("Failed to create new GarmentCD")
                    }
                }
            case .dismiss:
                return .run { _ in await self.dismiss() }
            case .binding:
                return .none
            }
        }
    }
}

struct AddGarmentView: View {
    @Bindable var store: Store<AddGarment.State, AddGarment.Action>
    enum FocusField { case itemName }
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField(text: $store.name) {
                    Text("Enter garment name")
                    .font(.largeTitle)
                }
				.font(.largeTitle)
                .keyboardShortcut(.defaultAction)
                .onSubmit { store.send(.save) }
                .focused($focusedField, equals: .itemName)
                .padding(.horizontal, 16)
                Spacer()
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.dismiss)
                    } label: {
                        Text("Dismiss")
                    }
                    .environment(\.colorScheme, .dark)
                }
                                
                ToolbarItem(placement: .primaryAction) {
                    Button{
                        store.send(.save)
                    } label: {
                        Text("Save")
                    }
                }
            }
        }        
        .onAppear {
            focusedField = .itemName
        }
    }
}

#Preview {
	AddGarmentView(store: Store(initialState: AddGarment.State(name: ""), reducer: {
		AddGarment()
	}))
}
