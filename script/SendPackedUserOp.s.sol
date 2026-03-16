// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract SendPackedUserOp is Script {
    function generateSignedUserOp(
        address sender,
        bytes memory callData,
        HelperConfig.NetworkConfig memory config
    ) public view returns (PackedUserOperation memory userOp) {
        userOp = generateUserOp(sender, callData);
    
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.deployer, digest);
        }                  
        userOp.signature = abi.encodePacked(r, s, v); // Note the order
    }

    function generateMultiSignedUserOp(
        address sender,
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        uint256[] memory signerKeys
    ) public view returns (PackedUserOperation memory userOp) {
        userOp = generateUserOp(sender, callData);

        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        bytes memory packedSignatures;
        for (uint256 i = 0; i < signerKeys.length; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKeys[i], digest);
            packedSignatures = bytes.concat(packedSignatures, abi.encodePacked(r, s, v));
        }

        userOp.signature = packedSignatures;
    }

    function generateUserOp(
        address sender,
        bytes memory callData
    ) public pure returns (PackedUserOperation memory userOp) {
        // Set some reasonable default gas limits so EntryPoint can allocate enough gas for validation
        // and execution. `accountGasLimits` is packed as (verificationGasLimit << 128) | callGasLimit.
        uint128 verificationGasLimit = 500_000;
        uint128 callGasLimit = 500_000;
        bytes32 accountGasLimits = bytes32((uint256(verificationGasLimit) << 128) | uint256(callGasLimit));

        userOp = PackedUserOperation({
            sender: sender,
            nonce: 0,
            initCode: "",
            callData: callData,
            accountGasLimits: accountGasLimits,
            preVerificationGas: 21000,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });
    }
}
