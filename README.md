# KLEManager – Usage Guide

## Setup

```swift
import CoreBluetooth
import KLE_BLE_SDK

 @MainActor
final class BLECoordinator: NSObject, KLEManagerDelegate {
    override init() {
        super.init()
        KLEManager.shared.delegate = self
    }

    func onTargetDeviceFound(device: ZenLockDevice) {}
    func onDeviceConnected() {}
    func onDeviceDisconnected() {}
    func onError(error: String) {}
    func onScanTimeOut() {}
    func onCommandSent() {}
}
```

**Note:** `startTrip()` uses SDK-managed PIN internally.

## Usage

### 1. Start Scan
```swift
KLEManager.shared.startScan(deviceName: "ENTITY_ID") // IMEI / target name
```

Wait for:
```swift
func onTargetDeviceFound(device: ZenLockDevice) {
    // Target found -> now start trip (connect)
}
```

### 2. Connect / Disconnect

```swift
KLEManager.shared.startTrip() // Connects and performs PIN handshake internally
KLEManager.shared.endTrip()   // Disconnect
```

### 3. Commands

```swift
KLEManager.shared.sendCommand(.immobilizeOn)
KLEManager.shared.sendCommand(.immobilizeOff)
KLEManager.shared.sendCommand(.ignitionOn)
KLEManager.shared.sendCommand(.ignitionOff)
```

## Delegate Events

```swift
func onTargetDeviceFound(device: ZenLockDevice) { }
func onDeviceConnected() { }      // Command-ready
func onDeviceDisconnected() { }
func onError(error: String) { }
func onScanTimeOut() { }
func onCommandSent() { }
```

## Typical Flow

`startScan` -> wait for `onTargetDeviceFound` -> `startTrip` -> wait for `onDeviceConnected` -> send commands -> `endTrip`.
