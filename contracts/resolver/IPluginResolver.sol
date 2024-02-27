// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISchemaResolver } from "./ISchemaResolver.sol";
import { Attestation } from "../Common.sol";

interface IPluginResolver is ISchemaResolver {

  /// @notice Provides an external function for the UsePluginResolver to call.
  /// @param attestation The new attestation.
  /// @param value Explicit ETH amount which was sent with the attestation.
  /// @return Whether the attestation is valid.
  function publicOnAttest(Attestation calldata attestation, uint256 value) external returns (bool);
}