// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "hardhat/console.sol";

import { Semver } from "./Semver.sol";
import { IPluginRegistry } from "./IPluginRegistry.sol";

/// @title PluginRegistry
/// @notice The global plugin registry.
contract PluginRegistry is IPluginRegistry {
    error AlreadyExists();

    // The global mapping between plugin ids and their owners
    mapping(bytes32 => address) public _pluginOwners; // pluginId => owner
    // A global plugin counter
    uint256 private _pluginCounter;
    // a global mapping between plugin ids and resolver contracts
    mapping(bytes32 => address payable) public _pluginResolvers; // pluginId => resolver

    /// @dev Creates a new PluginRegistry instance.
    constructor() {}

    /// @inheritdoc IPluginRegistry
    function setupPlugin() public returns (bytes32) {
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
    function getPluginOwner(bytes32 pluginId) external view returns (address) {
        return _pluginOwners[pluginId];
    }

    /// @inheritdoc IPluginRegistry
    function setPluginResolver(bytes32 pluginId, address payable resolver) public {
        require(msg.sender == _pluginOwners[pluginId], "Not owner");
        _pluginResolvers[pluginId] = resolver;
    }

    /// @inheritdoc IPluginRegistry
    function getPluginResolver(bytes32 pluginId) external view returns (address payable) {
        return _pluginResolvers[pluginId];
    }

    /// @inheritdoc IPluginRegistry
    function setUpPluginAndAssignResolver(address payable resolver) external returns (bytes32) {
        bytes32 uid = setupPlugin();
        setPluginResolver(uid, resolver);
        console.log('returning uid');
        console.logBytes32(uid);
        return uid;
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