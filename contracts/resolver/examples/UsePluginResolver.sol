// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "hardhat/console.sol";

import { SchemaResolver } from "../SchemaResolver.sol";
import { ISchemaResolver } from "../ISchemaResolver.sol";
import { IEAS, Attestation } from "../../IEAS.sol";
import { PluginRegistry } from '../../PluginRegistry.sol';
import { IPluginRegistry } from '../../IPluginRegistry.sol';
import { IPluginResolver } from '../IPluginResolver.sol';
import { AttestationResolver } from './AttestationResolver.sol';

/// @title UsePluginResolver
/// @notice A middleware resolver for calling your plugin resolver.
contract UsePluginResolver is SchemaResolver {
    error OutOfBounds();

    // The global PluginRegistry contract.
    IPluginRegistry internal immutable _pluginRegistry;
    // a struct representing the a schema with a pluginId field
    struct PluginSchema {
        bytes32 pluginId;
    }

    constructor(IEAS eas, IPluginRegistry pluginRegistry) SchemaResolver(eas) {
        _pluginRegistry = pluginRegistry;
    }

    function onAttest(Attestation calldata attestation, uint256 value) internal override returns (bool) {
        bytes32 uid = _toBytes32(attestation.data, 0);
        Attestation memory targetAttestation = _eas.getAttestation(uid);
        // check the pluginId in the attestation data
        PluginSchema memory schema = abi.decode(targetAttestation.data, (PluginSchema));
        console.log('schema.pluginId:');
        console.logBytes32(schema.pluginId);
        address payable resolver = IPluginRegistry(_pluginRegistry).getPluginResolver(schema.pluginId);
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
}