import SwiftUI
import ComposableArchitecture

@Reducer
struct AddGarment {
	
	@Reducer(state: .equatable)
	public enum Destination {
		case alert(AlertState<Alert>)
		
		public enum Alert {
			case createFail
		}
	}
	
    @ObservableState
    struct State: Equatable {
		@Presents public var destination: Destination.State?
        var name: String
    }
	
	enum Action: BindableAction {
		case destination(PresentationAction<Destination.Action>)
		case binding(BindingAction<State>)
        case create
        case dismiss
		case createError
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.garments) var garments
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .dismiss:
                return .run { _ in await self.dismiss() }
			case .create:
				return .run { [name = state.name] send in
					do {
						try garments.create(name)
						await send(.dismiss)
					} catch {
						await send(.createError)
					}
				}
			case .createError:
				state.destination = .alert(.init(title: TextState("Nothing to Save"), message: state.name.isEmpty ? TextState(verbatim: "Enter a name!") : nil, buttons: [.default(TextState("OK"))]))
				return .none
				
			case .binding, .destination:
                return .none
            }
        }
		.ifLet(\.$destination, action: \.destination)
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
                .onSubmit { store.send(.create) }
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
                        store.send(.create)
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
        .onAppear {
            focusedField = .itemName
        }
		.alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
}

#Preview {
	previewInMemory = true
	return AddGarmentView(store: Store(initialState: AddGarment.State(name: ""), reducer: {
		AddGarment()
	}))
}
