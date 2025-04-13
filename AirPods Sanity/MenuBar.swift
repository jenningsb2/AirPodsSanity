//
// Created by Tobias Punke on 27.08.22.
//

import AppKit
import Foundation
import LaunchAtLogin
import SimplyCoreAudio

class MenuBar
{
    private let _SimplyCoreAudio: SimplyCoreAudio
    private let _Preferences: Preferences

    private var _InputDeviceItems: [NSMenuItem]
    private var _OutputDeviceItems: [NSMenuItem]

    private var _StatusBarItem: NSStatusItem
    private var _lastSelectedPriorityInputDeviceName: String?
    private var _lastSelectedPriorityOutputDeviceName: String?

    init()
    {
        self._SimplyCoreAudio = SimplyCoreAudio()
        self._Preferences = Preferences.Instance

        self._InputDeviceItems = []
        self._OutputDeviceItems = []
        self._lastSelectedPriorityInputDeviceName = nil
        self._lastSelectedPriorityOutputDeviceName = nil

        self._StatusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        self.CreateStatusItem()
        self.SetShowInMenuBar()
        self.SetShowInDock()
    }

    private func CreateStatusItem()
    {
        let __Image = NSImage(named: "airpods-icon")

        __Image?.isTemplate = true

        if let __Button = self._StatusBarItem.button
        {
            __Button.toolTip = NSLocalizedString("MenuBar.ToolTip", comment: "")

            if __Image != nil
            {
                __Button.image = __Image
            }
            else
            {
                __Button.title = NSLocalizedString("MenuBar.ToolTip", comment: "")
            }
        }
    }

    public func CreateMenu()
    {
        self._lastSelectedPriorityInputDeviceName = nil
        self._lastSelectedPriorityOutputDeviceName = nil

        self._InputDeviceItems.removeAll()
        self._InputDeviceItems = self.CreateInputDeviceItems(simply: self._SimplyCoreAudio, preferences: self._Preferences)

        self._OutputDeviceItems.removeAll()
        self._OutputDeviceItems = self.CreateOutputDeviceItems(simply: self._SimplyCoreAudio, preferences: self._Preferences)

        let __Menu = NSMenu()

        // App controls section
        let enableItem = self.CreateIsEnabledItem(preferences: self._Preferences)
        enableItem.title = "Enable Input Device Auto-Switch"
        __Menu.addItem(enableItem)

        __Menu.addItem(NSMenuItem.separator())

        // Settings section
        let settingsHeader = NSMenuItem()
        settingsHeader.title = "Settings"
        settingsHeader.isEnabled = false
        __Menu.addItem(settingsHeader)
        
        __Menu.addItem(self.CreateLaunchOnLoginItem(preferences: self._Preferences))
        __Menu.addItem(self.CreateShowInMenuBarItem(preferences: self._Preferences))
        __Menu.addItem(self.CreateShowInDockItem(preferences: self._Preferences))

        __Menu.addItem(NSMenuItem.separator())

        // Add input and output device sections without top-level headers
        for item in self._InputDeviceItems {
            __Menu.addItem(item)
        }

        __Menu.addItem(NSMenuItem.separator())

        for item in self._OutputDeviceItems {
            __Menu.addItem(item)
        }

        __Menu.addItem(NSMenuItem.separator())
        __Menu.addItem(self.CreateQuitApplicationItem())

        self.SetShowInMenuBar()
        self._StatusBarItem.menu = __Menu
    }

    public var IsVisible: Bool
    {
        get
        {
            return self._StatusBarItem.isVisible
        }
    }
    
    public func Show()
    {
        self._StatusBarItem.isVisible = true;
    }
    
    public func Hide()
    {
        self._StatusBarItem.isVisible = false;
    }
    
    private func SetShowInMenuBar()
    {
        self._StatusBarItem.isVisible = self._Preferences.ShowInMenuBar
    }
    
    private func SetLaunchOnLogin()
    {
        LaunchAtLogin.isEnabled = self._Preferences.LaunchOnLogin
    }
    
    private func SetShowInDock()
    {
        let __Preferences = self._Preferences

        if __Preferences.ShowInDock
        {
            NSApp.setActivationPolicy(.regular)
        }
        else
        {
            NSApp.setActivationPolicy(.prohibited)
        }
    }
    
    private func CreateLaunchOnLoginItem(preferences: Preferences) -> NSMenuItem
    {
        let __MenuItem = NSMenuItem()

        __MenuItem.title = NSLocalizedString("MenuBar.LaunchOnLogin", comment: "")
        __MenuItem.target = self
        __MenuItem.action = #selector(OnToggleLaunchOnLogin(_:))

        if preferences.LaunchOnLogin
        {
            __MenuItem.state = NSControl.StateValue.on
        }
        else
        {
            __MenuItem.state = NSControl.StateValue.off
        }

        return __MenuItem
    }
    
    private func CreateShowInMenuBarItem(preferences: Preferences) -> NSMenuItem
    {
        let __MenuItem = NSMenuItem()

        __MenuItem.title = NSLocalizedString("MenuBar.ShowInMenuBar", comment: "")
        __MenuItem.target = self
        __MenuItem.action = #selector(OnToggleShowInMenuBar(_:))

        if preferences.ShowInMenuBar
        {
            __MenuItem.state = NSControl.StateValue.on
        }
        else
        {
            __MenuItem.state = NSControl.StateValue.off
        }

        return __MenuItem
    }

    private func CreateShowInDockItem(preferences: Preferences) -> NSMenuItem
    {
        let __MenuItem = NSMenuItem()

        __MenuItem.title = NSLocalizedString("MenuBar.ShowInDock", comment: "")
        __MenuItem.target = self
        __MenuItem.action = #selector(OnToggleShowInDock(_:))

        if preferences.ShowInDock
        {
            __MenuItem.state = NSControl.StateValue.on
        }
        else
        {
            __MenuItem.state = NSControl.StateValue.off
        }

        return __MenuItem
    }

    private func CreateIsEnabledItem(preferences: Preferences) -> NSMenuItem
    {
        let __MenuItem = NSMenuItem()

        __MenuItem.title = NSLocalizedString("MenuBar.IsEnabled", comment: "")
        __MenuItem.target = self
        __MenuItem.action = #selector(OnToggleIsEnabled(_:))

        if preferences.IsEnabled
        {
            __MenuItem.state = NSControl.StateValue.on
        }
        else
        {
            __MenuItem.state = NSControl.StateValue.off
        }

        return __MenuItem
    }

    private func CreateQuitApplicationItem() -> NSMenuItem
    {
        let __QuitLabel = NSLocalizedString("MenuBar.Quit", comment: "")
        let __QuitShortcut = NSLocalizedString("MenuBar.QuitShortcut", comment: "")

        return NSMenuItem(title: __QuitLabel, action: #selector(NSApplication.terminate(_:)), keyEquivalent: __QuitShortcut)
    }

    private func CreateInputDeviceItems(simply: SimplyCoreAudio, preferences: Preferences) -> [NSMenuItem]
    {
        let __AllInputDevices = simply.allInputDevices.sorted { $0.name < $1.name }
        var __MenuItems: [NSMenuItem] = []
        let __PriorityNames = preferences.PriorityInputDeviceNames

        if !__PriorityNames.isEmpty {
            let __PriorityHeader = NSMenuItem()
            __PriorityHeader.title = "Priority Input Devices"
            __PriorityHeader.isEnabled = false
            __MenuItems.append(__PriorityHeader)

            // Add priority devices with numbers and submenus
            for (index, deviceName) in __PriorityNames.enumerated() {
                if let device = __AllInputDevices.first(where: { $0.name == deviceName }) {
                    let __MenuItem = NSMenuItem()
                    __MenuItem.title = "\(index + 1). \(device.name)"
                    __MenuItem.representedObject = device.name
                    __MenuItem.target = self
                    __MenuItem.action = nil
                    __MenuItem.state = .on

                    // Create submenu for this device (reordering/removal)
                    let submenu = NSMenu()

                    // Only show Move Up if not first
                    if index > 0 {
                        let moveUpItem = NSMenuItem()
                        moveUpItem.title = "Move Up"
                        moveUpItem.target = self
                        moveUpItem.action = #selector(OnMoveInputDeviceUp(_:))
                        moveUpItem.representedObject = device.name
                        submenu.addItem(moveUpItem)
                    }

                    // Only show Move Down if not last
                    if index < __PriorityNames.count - 1 {
                        let moveDownItem = NSMenuItem()
                        moveDownItem.title = "Move Down"
                        moveDownItem.target = self
                        moveDownItem.action = #selector(OnMoveInputDeviceDown(_:))
                        moveDownItem.representedObject = device.name
                        submenu.addItem(moveDownItem)
                    }

                    if submenu.items.count > 0 {
                        submenu.addItem(NSMenuItem.separator())
                    }

                    let removeItem = NSMenuItem()
                    removeItem.title = "Remove from Priority List"
                    removeItem.target = self
                    removeItem.action = #selector(OnRemoveInputFromPriority(_:))
                    removeItem.representedObject = device.name
                    submenu.addItem(removeItem)

                    __MenuItem.submenu = submenu
                    __MenuItems.append(__MenuItem)
                }
            }

            __MenuItems.append(NSMenuItem.separator())
        }

        let __OtherHeader = NSMenuItem()
        __OtherHeader.title = "Other Input Devices"
        __OtherHeader.isEnabled = false
        __MenuItems.append(__OtherHeader)

        // Add non-priority devices with "Add to Priority List" submenu
        for device in __AllInputDevices.filter({ !__PriorityNames.contains($0.name) }) {
            let __MenuItem = NSMenuItem()
            __MenuItem.title = device.name
            __MenuItem.representedObject = device.name
            __MenuItem.target = self
            __MenuItem.action = nil
            __MenuItem.state = .off

            // Create submenu for adding to priority list
            let submenu = NSMenu()
            let addItem = NSMenuItem()
            addItem.title = "Add to Priority List"
            addItem.target = self
            addItem.action = #selector(AddInputDeviceToPriority(_:))
            addItem.representedObject = device.name
            submenu.addItem(addItem)

            __MenuItem.submenu = submenu
            __MenuItems.append(__MenuItem)
        }

        return __MenuItems
    }

    private func CreateOutputDeviceItems(simply: SimplyCoreAudio, preferences: Preferences) -> [NSMenuItem]
    {
        let __AllOutputDevices = simply.allOutputDevices.sorted { $0.name < $1.name }
        var __MenuItems: [NSMenuItem] = []
        let __PriorityNames = preferences.PriorityOutputDeviceNames

        if !__PriorityNames.isEmpty {
            let __PriorityHeader = NSMenuItem()
            __PriorityHeader.title = "Priority Output Devices"
            __PriorityHeader.isEnabled = false
            __MenuItems.append(__PriorityHeader)

            // Add priority devices with numbers and submenus
            for (index, deviceName) in __PriorityNames.enumerated() {
                if let device = __AllOutputDevices.first(where: { $0.name == deviceName }) {
                    let __MenuItem = NSMenuItem()
                    __MenuItem.title = "\(index + 1). \(device.name)"
                    __MenuItem.representedObject = device.name
                    __MenuItem.target = self
                    __MenuItem.action = nil
                    __MenuItem.state = .on

                    // Create submenu for this device
                    let submenu = NSMenu()

                    if index > 0 {
                        let moveUpItem = NSMenuItem()
                        moveUpItem.title = "Move Up"
                        moveUpItem.target = self
                        moveUpItem.action = #selector(OnMoveOutputDeviceUp(_:))
                        moveUpItem.representedObject = device.name
                        submenu.addItem(moveUpItem)
                    }

                    if index < __PriorityNames.count - 1 {
                        let moveDownItem = NSMenuItem()
                        moveDownItem.title = "Move Down"
                        moveDownItem.target = self
                        moveDownItem.action = #selector(OnMoveOutputDeviceDown(_:))
                        moveDownItem.representedObject = device.name
                        submenu.addItem(moveDownItem)
                    }

                    if submenu.items.count > 0 {
                        submenu.addItem(NSMenuItem.separator())
                    }

                    let removeItem = NSMenuItem()
                    removeItem.title = "Remove from Priority List"
                    removeItem.target = self
                    removeItem.action = #selector(OnRemoveOutputFromPriority(_:))
                    removeItem.representedObject = device.name
                    submenu.addItem(removeItem)

                    __MenuItem.submenu = submenu
                    __MenuItems.append(__MenuItem)
                }
            }

            __MenuItems.append(NSMenuItem.separator())
        }

        let __OtherHeader = NSMenuItem()
        __OtherHeader.title = "Other Output Devices"
        __OtherHeader.isEnabled = false
        __MenuItems.append(__OtherHeader)

        // Add non-priority devices with "Add to Priority List" submenu
        for device in __AllOutputDevices.filter({ !__PriorityNames.contains($0.name) }) {
            let __MenuItem = NSMenuItem()
            __MenuItem.title = device.name
            __MenuItem.representedObject = device.name
            __MenuItem.target = self
            __MenuItem.action = nil
            __MenuItem.state = .off

            // Create submenu for adding to priority list
            let submenu = NSMenu()
            let addItem = NSMenuItem()
            addItem.title = "Add to Priority List"
            addItem.target = self
            addItem.action = #selector(AddOutputDeviceToPriority(_:))
            addItem.representedObject = device.name
            submenu.addItem(addItem)

            __MenuItem.submenu = submenu
            __MenuItems.append(__MenuItem)
        }

        return __MenuItems
    }

    @objc private func OnToggleLaunchOnLogin(_ sender: NSMenuItem)
    {
        let __Preferences = self._Preferences
        let __State = sender.state

        if __State == NSControl.StateValue.on
        {
            __Preferences.LaunchOnLogin = false
            sender.state = NSControl.StateValue.off
        }
        else if __State == NSControl.StateValue.off
        {
            __Preferences.LaunchOnLogin = true
            sender.state = NSControl.StateValue.on
        }

        self.SetLaunchOnLogin()

        self._Preferences.WriteSettings()
    }
    
    @objc private func OnToggleShowInMenuBar(_ sender: NSMenuItem)
    {
        let __Preferences = self._Preferences
        let __State = sender.state

        if __State == NSControl.StateValue.on
        {
            __Preferences.ShowInMenuBar = false
            sender.state = NSControl.StateValue.off
        }
        else if __State == NSControl.StateValue.off
        {
            __Preferences.ShowInMenuBar = true
            sender.state = NSControl.StateValue.on
        }

        self.SetShowInMenuBar()
        
        self._Preferences.WriteSettings()
    }

    @objc private func OnToggleShowInDock(_ sender: NSMenuItem)
    {
        let __Preferences = self._Preferences
        let __State = sender.state

        if __State == NSControl.StateValue.on
        {
            __Preferences.ShowInDock = false
            sender.state = NSControl.StateValue.off
        }
        else if __State == NSControl.StateValue.off
        {
            __Preferences.ShowInDock = true
            sender.state = NSControl.StateValue.on
        }

        self.SetShowInDock()
        
        self._Preferences.WriteSettings()
    }

    @objc private func OnToggleIsEnabled(_ sender: NSMenuItem)
    {
        let __Preferences = self._Preferences
        let __State = sender.state

        if __State == NSControl.StateValue.on
        {
            __Preferences.IsEnabled = false
            sender.state = NSControl.StateValue.off
        }
        else if __State == NSControl.StateValue.off
        {
            __Preferences.IsEnabled = true
            sender.state = NSControl.StateValue.on
        }
        
        self._Preferences.WriteSettings()
    }

    @objc private func AddInputDeviceToPriority(_ sender: NSMenuItem) {
        guard let deviceName = sender.representedObject as? String else { return }
        if !self._Preferences.PriorityInputDeviceNames.contains(deviceName) {
            self._Preferences.PriorityInputDeviceNames.append(deviceName)
            self._Preferences.WriteSettings()
            self.CreateMenu()
            NSLog("[AirPodsSanity] Added '\(deviceName)' to priority input list via submenu.")
        }
    }

    @objc private func AddOutputDeviceToPriority(_ sender: NSMenuItem) {
        guard let deviceName = sender.representedObject as? String else { return }
        if !self._Preferences.PriorityOutputDeviceNames.contains(deviceName) {
            self._Preferences.PriorityOutputDeviceNames.append(deviceName)
            self._Preferences.WriteSettings()
            self.CreateMenu()
            NSLog("[AirPodsSanity] Added '\(deviceName)' to priority output list via submenu.")
        }
    }

    @objc private func OnMoveInputDeviceUp(_ sender: NSMenuItem) {
        guard let deviceName = sender.representedObject as? String,
              let currentIndex = self._Preferences.PriorityInputDeviceNames.firstIndex(of: deviceName),
              currentIndex > 0 else { return }

        self._Preferences.PriorityInputDeviceNames.swapAt(currentIndex, currentIndex - 1)
        self._Preferences.WriteSettings()
        self.CreateMenu()
    }

    @objc private func OnMoveInputDeviceDown(_ sender: NSMenuItem) {
        guard let deviceName = sender.representedObject as? String,
              let currentIndex = self._Preferences.PriorityInputDeviceNames.firstIndex(of: deviceName),
              currentIndex < self._Preferences.PriorityInputDeviceNames.count - 1 else { return }

        self._Preferences.PriorityInputDeviceNames.swapAt(currentIndex, currentIndex + 1)
        self._Preferences.WriteSettings()
        self.CreateMenu()
    }

    @objc private func OnMoveOutputDeviceUp(_ sender: NSMenuItem) {
        guard let deviceName = sender.representedObject as? String,
              let currentIndex = self._Preferences.PriorityOutputDeviceNames.firstIndex(of: deviceName),
              currentIndex > 0 else { return }

        self._Preferences.PriorityOutputDeviceNames.swapAt(currentIndex, currentIndex - 1)
        self._Preferences.WriteSettings()
        self.CreateMenu()
    }

    @objc private func OnMoveOutputDeviceDown(_ sender: NSMenuItem) {
        guard let deviceName = sender.representedObject as? String,
              let currentIndex = self._Preferences.PriorityOutputDeviceNames.firstIndex(of: deviceName),
              currentIndex < self._Preferences.PriorityOutputDeviceNames.count - 1 else { return }

        self._Preferences.PriorityOutputDeviceNames.swapAt(currentIndex, currentIndex + 1)
        self._Preferences.WriteSettings()
        self.CreateMenu()
    }

    @objc private func OnRemoveInputFromPriority(_ sender: NSMenuItem) {
        guard let deviceName = sender.representedObject as? String else { return }
        self._Preferences.PriorityInputDeviceNames.removeAll { $0 == deviceName }
        self._Preferences.WriteSettings()
        self.CreateMenu()
    }

    @objc private func OnRemoveOutputFromPriority(_ sender: NSMenuItem) {
        guard let deviceName = sender.representedObject as? String else { return }
        self._Preferences.PriorityOutputDeviceNames.removeAll { $0 == deviceName }
        self._Preferences.WriteSettings()
        self.CreateMenu()
    }
}
