// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Semver } from "./Semver.sol";
import { IPluginRegistry } from "./IPluginRegistry.sol";

/// @title PluginRegistry
/// @notice The global plugin registry.
contract PluginRegistry is IPluginRegistry, Semver {
    error AlreadyExists();

    // The global mapping between plugin ids and their owners
    mapping(bytes32 => address) public _pluginOwners;
    // A global plugin counter
    uint256 private _pluginCounter;

    /// @dev Creates a new PluginRegistry instance.
    constructor() Semver(0, 0, 1) {}

    /// @inheritdoc IPluginRegistry
    function setupPlugin() external returns (bytes32) {
        bytes32 uid = _getUID();
        if (_pluginOwners[uid] != address(0)) {
            revert AlreadyExists();
        }

        _pluginOwners[uid] = msg.sender;
        emit Registered(uid, msg.sender);

        return uid;
    }

    /// @inheritdoc IPluginRegistry
    function changePluginOwner(bytes32 pluginId, address newOwner) external {
        require(msg.sender == _pluginOwners[pluginId], "Not owner");
        _pluginOwners[pluginId] = newOwner;
    }

    /// @inheritdoc IPluginRegistry
    function getPlugin(bytes32 uid) external view returns (address) {
        return _pluginOwners[uid];
    }

    /// @dev Calculates a UID for a given plugin.
    /// @return plugin UID.
    function _getUID() private returns (bytes32) {
        _pluginCounter++; // Increment counter for uniqueness
        return keccak256(
            abi.encodePacked(
                block.timestamp, 
                msg.sender, 
                _pluginCounter
            )
        );
    }
}