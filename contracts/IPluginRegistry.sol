// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ISemver } from "./ISemver.sol";

// import { IPluginResolver } from "./resolver/IPluginResolver.sol";

/// @title IPluginRegistry
/// @notice The interface of global attestation plugins for the Ethereum Attestation Service protocol.
interface IPluginRegistry {
    /// @notice Emitted when a new plugin has been registered
    /// @param uid The plugin UID.
    /// @param registerer The address of the account used to register the plugin.
    event Registered(bytes32 indexed uid, address indexed registerer);

    /// @notice Sets up a new plugin
    /// @return The UID of the new plugin.
    function setupPlugin() external returns (bytes32);

    /// @notice Changes the owner of a plugin.
    /// @dev This function allows the current owner of the plugin to transfer ownership to another address.
    /// @dev Reverts if the caller is not the current owner of the plugin.
    /// @param pluginId The unique identifier of the plugin.
    /// @param newOwner The address of the new owner to set.
    function changePluginOwner(bytes32 pluginId, address newOwner) external;

    /// @notice Returns the owner of an existing plugin by UID
    /// @param pluginId The pluginId of the plugin to retrieve.
    /// @return The address of the plugin owner.
    function getPluginOwner(bytes32 pluginId) external view returns (address);

    /// @notice Sets the resolver for a plugin.
    /// @dev This function allows the owner of the plugin to set the resolver for the plugin.
    /// @dev Reverts if the caller is not the owner of the plugin.
    /// @param pluginId The unique identifier of the plugin.
    /// @param resolver The address of the resolver to set.
    function setPluginResolver(bytes32 pluginId, address payable resolver) external;

    /// @notice Returns the resolver for a plugin by UID
    /// @param pluginId The pluginId of the plugin to retrieve.
    /// @return The address of the plugin resolver.
    function getPluginResolver(bytes32 pluginId) external view returns (address payable);

    /// @notice Sets up a new plugin and assigns a resolver to it.
    /// @dev This function allows the caller to set up a new plugin and assign a resolver to it.
    /// @param resolver The address of the resolver to set.
    /// @return The UID of the new plugin.
    function setUpPluginAndAssignResolver(address payable resolver) external returns (bytes32);
}