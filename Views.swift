import SwiftUI

// MARK: - Root

struct ContentView: View {
    @State private var licensed = false

    var body: some View {
        if licensed {
            DashboardView()
        } else {
            LicenseView { licensed = true }
        }
    }
}

// MARK: - License

struct LicenseView: View {
    @StateObject private var manager = LicenseManager()
    @State private var inputKey = ""
    let onValidated: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.06, blue: 0.12).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.purple)

                Text("IOSPRIVATE")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Enter license key")
                    .foregroundColor(.gray)

                TextField("License Key", text: $inputKey)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                if let error = manager.errorMessage {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                Button {
                    Task {
                        await manager.validate(key: inputKey)
                        if manager.isValidated { onValidated() }
                    }
                } label: {
                    if manager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Validate").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(inputKey.isEmpty || manager.isLoading)
            }
            .padding()
        }
    }
}

// MARK: - Dashboard

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var config = PanelConfig.default
    @Published var isLoading = false
    @Published var statusMessage: String?

    func load() async {
        isLoading = true
        do {
            config = try await APIService.shared.fetchPanelConfig()
            statusMessage = "Config loaded"
        } catch {
            statusMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggle(_ kp: WritableKeyPath<PanelConfig, Bool>) {
        config[keyPath: kp].toggle()
    }

    func pushUpdate() async {
        isLoading = true
        do {
            try await APIService.shared.updatePanelConfig(config)
            statusMessage = "Updated"
        } catch {
            statusMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()

    private let features: [(String, WritableKeyPath<PanelConfig, Bool>)] = [
        ("ESP", \.esp),
        ("NAME", \.name),
        ("BOX", \.box),
        ("DISTANCE", \.distance),
        ("FOV", \.fov)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.12).ignoresSafeArea()
                VStack(spacing: 16) {
                    ForEach(features, id: \.0) { label, kp in
                        HStack {
                            Text(label)
                                .foregroundColor(.white)
                                .font(.headline)
                            Spacer()
                            Text(vm.config[keyPath: kp] ? "ON" : "OFF")
                                .foregroundColor(vm.config[keyPath: kp] ? .green : .gray)
                            Toggle("", isOn: Binding(
                                get: { vm.config[keyPath: kp] },
                                set: { _ in vm.toggle(kp) }
                            ))
                            .labelsHidden()
                            .tint(.purple)
                        }
                        .padding()
                        .background(Color(red: 0.14, green: 0.11, blue: 0.20))
                        .cornerRadius(12)
                    }

                    if let msg = vm.statusMessage {
                        Text(msg).font(.caption).foregroundColor(.gray)
                    }

                    Button {
                        Task { await vm.pushUpdate() }
                    } label: {
                        Text("Update config")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(vm.isLoading)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("IOSPRIVATE")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") { Task { await vm.load() } }
                        .foregroundColor(.purple)
                }
            }
            .task { await vm.load() }
        }
    }
}
