// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ISemver } from "./ISemver.sol";

// import { IPluginResolver } from "./resolver/IPluginResolver.sol";

/// @title IPluginRegistry
/// @notice The interface of global attestation plugins for the Ethereum Attestation Service protocol.
interface IPluginRegistry is ISemver {
    /// @notice Emitted when a new plugin has been registered
    /// @param uid The plugin UID.
    /// @param registerer The address of the account used to register the plugin.
    event Registered(bytes32 indexed uid, address indexed registerer);

    /// @notice Sets up a new plugin
    /// @return The UID of the new plugin.
    function setupPlugin() external returns (bytes32);

    /// @notice Changes the owner of a plugin.
    /// @dev This function allows the current owner of the plugin to transfer ownership to another address.
    /// @param pluginId The unique identifier of the plugin.
    /// @param newOwner The address of the new owner to set.
    /// @dev Reverts if the caller is not the current owner of the plugin.
    function changePluginOwner(bytes32 pluginId, address newOwner) external;

    /// @notice Returns the owner of an existing plugin by UID
    /// @param uid The UID of the plugin to retrieve.
    /// @return The address of the plugin owner.
    function getPlugin(bytes32 uid) external view returns (address);
}