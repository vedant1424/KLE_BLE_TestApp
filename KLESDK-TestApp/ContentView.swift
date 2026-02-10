import SwiftUI
import KLE_BLE_SDK

@MainActor
final class TestViewModel: ObservableObject, KLEManagerDelegate {
    struct LogEntry: Identifiable {
        let id = UUID()
        let message: String
        let color: Color
    }

    @Published var imeiInput = ""
    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var isConnected = false
    @Published private(set) var isScanning = false
    @Published private(set) var isTripStarted = false
    @Published private(set) var hasTargetDevice = false

    var canStartScan: Bool {
        !imeiInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isScanning
    }

    var canStartTrip: Bool {
        hasTargetDevice && !isConnected
    }

    var canSendCommands: Bool {
        isConnected && isTripStarted
    }

    init() {
        KLEManager.shared.delegate = self
    }

    deinit {
        if KLEManager.shared.delegate === self {
            KLEManager.shared.delegate = nil
        }
    }

    func startScanByName() {
        guard canStartScan else { return }
        hasTargetDevice = false
        isTripStarted = false
        isScanning = true

        let target = imeiInput.trimmingCharacters(in: .whitespacesAndNewlines)
        addLog("Scanning target: \(target)", color: .blue)
        KLEManager.shared.startScan(deviceName: target)
    }

    func startTrip() {
        guard canStartTrip else { return }
        addLog("Starting trip", color: .green)
        KLEManager.shared.startTrip()
    }

    func endTrip() {
        addLog("Ending trip", color: .red)
        KLEManager.shared.endTrip()
    }

    func sendCommand(_ command: ZenLockCommand) {
        guard canSendCommands else { return }
        KLEManager.shared.sendCommand(command)
    }

    private func addLog(_ message: String, color: Color = .primary) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append(LogEntry(message: "[\(timestamp)] \(message)", color: color))
    }

    func onTargetDeviceFound(device: ZenLockDevice) {
        hasTargetDevice = true
        isScanning = false
        addLog("Target found: \(device.name) RSSI:\(device.rssi)", color: .orange)
    }

    func onDeviceConnected() {
        isConnected = true
        isScanning = false
        isTripStarted = true
        addLog("Connected and command-ready", color: .green)
    }

    func onDeviceDisconnected() {
        isConnected = false
        isTripStarted = false
        hasTargetDevice = false
        addLog("Device disconnected", color: .red)
    }

    func onError(error: String) {
        isScanning = false
        addLog("Error: \(error)", color: .red)
    }

    func onScanTimeOut() {
        isScanning = false
        hasTargetDevice = false
        addLog("Scan timed out", color: .red)
    }

    func onCommandSent() {
        addLog("Command sent", color: .blue)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = TestViewModel()
    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target IMEI / Name")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Enter target (e.g. 11717433)", text: $viewModel.imeiInput)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
                .padding(.horizontal)

                if viewModel.isConnected {
                    Button("End Trip (Disconnect)") {
                        viewModel.endTrip()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding(.horizontal)
                } else {
                    HStack(spacing: 10) {
                        Button("Scan by Name") {
                            viewModel.startScanByName()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canStartScan)

                        Button("Start Trip") {
                            viewModel.startTrip()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canStartTrip)
                    }
                    .padding(.horizontal)
                }

                Text(viewModel.canSendCommands ? "Trip in Progress" : "Trip Not Started")
                    .font(.headline)
                    .foregroundColor(viewModel.canSendCommands ? .green : .secondary)

                LazyVGrid(columns: gridColumns, spacing: 12) {
                    CommandButton(title: "Ignition ON", color: .green) {
                        viewModel.sendCommand(.ignitionOn)
                    }
                    CommandButton(title: "Ignition OFF", color: .red) {
                        viewModel.sendCommand(.ignitionOff)
                    }
                    CommandButton(title: "Immobilize ON", color: .orange) {
                        viewModel.sendCommand(.immobilizeOn)
                    }
                    CommandButton(title: "Immobilize OFF", color: .gray) {
                        viewModel.sendCommand(.immobilizeOff)
                    }
                }
                .padding(.horizontal)
                .disabled(!viewModel.canSendCommands)
                .opacity(viewModel.canSendCommands ? 1 : 0.5)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(viewModel.logs) { log in
                            Text(log.message)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(log.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 180)
            }
            .navigationTitle("KLE SDK Test")
        }
    }
}

struct CommandButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(color)
                .cornerRadius(8)
        }
    }
}
