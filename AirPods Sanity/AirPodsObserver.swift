//
//  ObservableSCA.swift
//  AirPods Sanity
//
//  Created by Tobias Punke on 25.08.22.
//

import Foundation
import SimplyCoreAudio

class AirPodsObserver: ObservableObject
{
    private let _Preferences: Preferences
    private let _Simply: SimplyCoreAudio
    private let _NotificationCenter: NotificationCenter

    private var _Observers: [NSObjectProtocol]

    // Ensure this property exists for input correction fallback
    private var _FallbackInputDeviceName: String?

    init()
    {
        self._Preferences = Preferences.Instance
        self._Simply = SimplyCoreAudio()
        self._NotificationCenter = NotificationCenter.default
        self._Observers = []

        // Store the initial input device name on startup as a fallback
        self._FallbackInputDeviceName = self._Simply.defaultInputDevice?.name

        self.AddObservers()
        // Initial checks are now moved inside AddObservers to ensure observers are set first
    }

    deinit
    {
        self.RemoveObservers()
    }
}

// MARK: - Private Methods
private extension AirPodsObserver
{
    // ADD: Function to proactively set the default OUTPUT device
    func ApplyPriorityOutputDevice() {
        guard self._Preferences.IsEnabled else {
            NSLog("[AirPodsSanity] Automatic output device switching is disabled via main toggle.")
            return
        }

        NSLog("[AirPodsSanity] Applying priority output device check...")
        let availableOutputs = self._Simply.allOutputDevices

        var outputDeviceSet = false
        for priorityOutputName in self._Preferences.PriorityOutputDeviceNames {
            if let targetOutputDevice = availableOutputs.first(where: { $0.name == priorityOutputName }) {
                // Found the highest priority available output device
                if !targetOutputDevice.isDefaultOutputDevice {
                    NSLog("[AirPodsSanity] Setting default output to highest priority available device: \(priorityOutputName)")
                    self.RemoveObservers() // Prevent reacting to the change we're making temporarily
                    targetOutputDevice.isDefaultOutputDevice = true
                    self.AddObservers() // Re-add observers (safe to call even if already added)
                    outputDeviceSet = true
                    // Optional: Consider calling sample rate logic here if desired
                    // self.TrySetOptimalSampleRate(for: targetOutputDevice)
                } else {
                    NSLog("[AirPodsSanity] Highest priority available output '\(priorityOutputName)' is already default.")
                    outputDeviceSet = true // Already set correctly
                    // Optional: Still check sample rate?
                    // self.TrySetOptimalSampleRate(for: targetOutputDevice)
                }
                break // Stop after finding and processing the highest priority available output
            }
        }

        if !outputDeviceSet {
            NSLog("[AirPodsSanity] No priority output devices found/available. System default remains unchanged by app.")
        }
    }

    // KEEP: Reactive function to correct input device (ensure it exists and is correct)
    func CorrectInputDeviceIfNeeded() {
        guard self._Preferences.IsEnabled else {
            NSLog("[AirPodsSanity] Input Correction disabled.")
            return
        }

        guard let currentInputDevice = self._Simply.defaultInputDevice,
              let currentOutputDevice = self._Simply.defaultOutputDevice else {
            NSLog("[AirPodsSanity] Could not get current default devices for input check.")
            return
        }

        let isPriorityOutputConnected = self._Preferences.PriorityOutputDeviceNames.contains(currentOutputDevice.name)
        let isInputUndesiredAirPodsMic = self._Preferences.PriorityOutputDeviceNames.contains(currentInputDevice.name)

        if isPriorityOutputConnected && isInputUndesiredAirPodsMic {
            var switched = false
            for preferredInputName in self._Preferences.PriorityInputDeviceNames {
                if let targetInputDevice = self._Simply.allInputDevices.first(where: { $0.name == preferredInputName }) {
                    if targetInputDevice.id != currentInputDevice.id {
                        NSLog("[AirPodsSanity] Reactive: Output is '\(currentOutputDevice.name)', Input incorrect '\(currentInputDevice.name)'. Correcting to preferred input: '\(preferredInputName)'.")
                        self.RemoveObservers()
                        targetInputDevice.isDefaultInputDevice = true
                        self.AddObservers() // Safe to call again
                        switched = true
                        break
                    } else {
                         NSLog("[AirPodsSanity] Reactive: Preferred input '\(preferredInputName)' is already the current input. No correction needed for this one.")
                         switched = true
                         break
                    }
                }
            }
            if !switched {
                NSLog("[AirPodsSanity] Reactive: Output is '\(currentOutputDevice.name)', Input is '\(currentInputDevice.name)', but no available preferred input device found.")
            }
        } else if isPriorityOutputConnected && !isInputUndesiredAirPodsMic {
             NSLog("[AirPodsSanity] Reactive: Output is '\(currentOutputDevice.name)', Input is '\(currentInputDevice.name)' (correct). No input correction needed.")
             self._FallbackInputDeviceName = currentInputDevice.name
        } else {
            NSLog("[AirPodsSanity] Reactive: Priority output not connected. Storing current input '\(currentInputDevice.name)' as fallback.")
            self._FallbackInputDeviceName = currentInputDevice.name
        }
    }

    // KEEP: Optional Sample Rate function if used
    /*
    func TrySetOptimalSampleRate(for device: AudioDevice) { ... }
    */

    func AddObservers()
    {
        // Ensure observers are added only once
        guard self._Observers.isEmpty else { return }

        NSLog("[AirPodsSanity] Adding Observers (Hybrid).")
        self._Observers.append(contentsOf:[
            // CHANGE: Call ApplyPriorityOutputDevice when device list changes
            self._NotificationCenter.addObserver(forName: .deviceListChanged, object: nil, queue: .main) { [weak self] (notification) in
               NSLog("[AirPodsSanity] Notification received: .deviceListChanged")
               self?.ApplyPriorityOutputDevice() // Proactively set output
               // We also need to notify the MenuBar to update its display
               // Ideally, use a dedicated notification or shared state for this.
               NotificationCenter.default.post(name: .menuBarShouldUpdate, object: nil) // ADD Notification Post
            },

            // KEEP: Reactive input correction triggers
            self._NotificationCenter.addObserver(forName: .defaultInputDeviceChanged, object: nil, queue: .main) { [weak self] (_) in
                NSLog("[AirPodsSanity] Notification received: .defaultInputDeviceChanged")
                self?.CorrectInputDeviceIfNeeded()
            },
            self._NotificationCenter.addObserver(forName: .defaultOutputDeviceChanged, object: nil, queue: .main) { [weak self] (_) in
                NSLog("[AirPodsSanity] Notification received: .defaultOutputDeviceChanged")
                self?.CorrectInputDeviceIfNeeded() // Check if input needs correcting relative to the new output
            },

            // KEEP: Optional sample rate observer
            /*
             self._NotificationCenter.addObserver(forName: .deviceNominalSampleRateDidChange, object: nil, queue: .main) { ... }
            */
        ])
         // Apply initial checks AFTER observers are set up
         ApplyPriorityOutputDevice()
         CorrectInputDeviceIfNeeded()
    }

    // KEEP: RemoveObservers method (no changes needed)
    func RemoveObservers()
    {
        if !self._Observers.isEmpty {
            NSLog("[AirPodsSanity] Removing Observers.")
            for __Observer in self._Observers
            {
                self._NotificationCenter.removeObserver(__Observer)
            }
            self._Observers.removeAll()
        }
    }
}

// ADD: Custom Notification Name outside the class extension
extension Notification.Name {
    static let menuBarShouldUpdate = Notification.Name("eu.punke.AirPods-Sanity.menuBarShouldUpdate")
}
