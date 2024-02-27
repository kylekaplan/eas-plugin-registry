// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "hardhat/console.sol";

import { SchemaResolver } from "../SchemaResolver.sol";
import { ISchemaResolver } from "../ISchemaResolver.sol";
import { IEAS, Attestation } from "../../IEAS.sol";
import { IPluginRegistry } from './IPluginRegistry.sol';
import { IPluginResolver } from './IPluginResolver.sol';

/// @title UsePluginResolver
/// @notice A middleware resolver for calling your plugin resolver.
contract UsePluginResolver is SchemaResolver, IPluginRegistry {
    error OutOfBounds();
    error AlreadyExists();

    // The global mapping between plugin ids and their owners
    mapping(bytes32 => address) public _pluginOwners; // pluginId => owner
    // A global plugin counter
    uint256 private _pluginCounter;
    // a global mapping between plugin ids and resolver contracts
    mapping(bytes32 => address payable) public _pluginResolvers; // pluginId => resolver

    // a struct representing the a schema with a pluginId field
    struct PluginSchema {
        bytes32 pluginId;
    }

    constructor(IEAS eas) SchemaResolver(eas) {}

    function onAttest(Attestation calldata attestation, uint256 value) internal override returns (bool) {
        bytes32 uid = _toBytes32(attestation.data, 0);
        Attestation memory targetAttestation = _eas.getAttestation(uid);
        // check the pluginId in the attestation data
        PluginSchema memory schema = abi.decode(targetAttestation.data, (PluginSchema));
        console.log('schema.pluginId:');
        console.logBytes32(schema.pluginId);
        address payable resolver = getPluginResolver(schema.pluginId);
        // // log the resolver address
        console.log('resolver:');
        console.logAddress(resolver);
        if (resolver == address(0)) {
            console.log('resolver is address(0)');
            return true;
        }
        // delegate call to the resolver
        bool success = IPluginResolver(resolver).publicOnAttest(attestation, value);        
        console.log('success:');
        console.logBool(success);
        return success;
        
    }

    function onRevoke(Attestation calldata /*attestation*/, uint256 /*value*/) internal pure override returns (bool) {
        return true;
    }

    function toBytes32(bytes memory data, uint256 start) external pure returns (bytes32) {
        return _toBytes32(data, start);
    }

    function _toBytes32(bytes memory data, uint256 start) private pure returns (bytes32) {
        unchecked {
            if (data.length < start + 32) {
                revert OutOfBounds();
            }
        }

        bytes32 tempBytes32;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempBytes32 := mload(add(add(data, 0x20), start))
        }

        return tempBytes32;
    }


    // *********** functions for plugin registery ***********


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
    function getPluginResolver(bytes32 pluginId) public view returns (address payable) {
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