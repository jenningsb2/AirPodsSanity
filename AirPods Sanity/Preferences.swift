//
// Created by Tobias Punke on 27.08.22.
//

import Foundation

class Preferences
{
    private static var _Instance: Preferences?
    private let _PreferencesFile: PreferencesFile

    init(preferencesFile: PreferencesFile)
    {
        self._PreferencesFile = preferencesFile

        self.LaunchOnLogin = preferencesFile.LaunchOnLogin ?? true
        self.ShowInMenuBar = preferencesFile.ShowInMenuBar ?? true
        self.ShowInDock = preferencesFile.ShowInDock ?? false
        self.IsEnabled = preferencesFile.IsEnabled ?? true
        self.InputDeviceName = preferencesFile.InputDeviceName
        self.AirPodsDeviceNames = preferencesFile.AirPodsDeviceNames ?? []
        self.PriorityInputDeviceNames = preferencesFile.PriorityInputDeviceNames ?? []
        self.PriorityOutputDeviceNames = preferencesFile.PriorityOutputDeviceNames ?? []
    }
    
    static var Instance: Preferences
    {
        if _Instance == nil
        {
            _Instance = Preferences(preferencesFile: PreferencesLoader.LoadSettings())
        }

        return _Instance!
    }
    
    public var LaunchOnLogin: Bool
    public var ShowInMenuBar: Bool
    public var ShowInDock: Bool
    public var IsEnabled: Bool
    public var InputDeviceName: String?
    public var AirPodsDeviceNames: [String]
    public var PriorityInputDeviceNames: [String]
    public var PriorityOutputDeviceNames: [String]

    public func WriteSettings() -> Void
    {
        self._PreferencesFile.LaunchOnLogin = self.LaunchOnLogin
        self._PreferencesFile.ShowInMenuBar = self.ShowInMenuBar
        self._PreferencesFile.ShowInDock = self.ShowInDock
        self._PreferencesFile.IsEnabled = self.IsEnabled
        self._PreferencesFile.InputDeviceName = self.InputDeviceName
        self._PreferencesFile.AirPodsDeviceNames = self.AirPodsDeviceNames
        self._PreferencesFile.PriorityInputDeviceNames = self.PriorityInputDeviceNames
        self._PreferencesFile.PriorityOutputDeviceNames = self.PriorityOutputDeviceNames

        PreferencesLoader.WriteSettings(preferences: self._PreferencesFile)
    }
}
