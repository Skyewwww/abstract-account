// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimalAccount is IAccount {
    IEntryPoint public immutable entryPoint;
    mapping(address => bool) public isOwner;
    address[] private s_owners;
    uint256 public threshold;

    error MinimalAccount_NotFromEntryPoint();
    error MinimalAccount_NotFromEntryPointOrOwner();
    error MinimalAccount_CallFailded(bytes data);
    error MinimalAccount_PayPrefundFailded();
    error MinimalAccount_InvalidThreshold();
    error MinimalAccount_InvalidOwner();
    error MinimalAccount_DuplicateOwner();

    modifier requireFromEntryPoint {
        if (msg.sender != address(entryPoint)) revert MinimalAccount_NotFromEntryPoint();
        _;
    }

    modifier requireFromEntryPointOrOwner {
        if (msg.sender != address(entryPoint) && !(threshold == 1 && isOwner[msg.sender])) {
            revert MinimalAccount_NotFromEntryPointOrOwner();
        }
        _;
    }

    constructor(address _entryPoint, address[] memory owners, uint256 _threshold) {
        entryPoint = IEntryPoint(_entryPoint);
        _initializeOwners(owners, _threshold);
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }
    
    function execute(
        address dest, 
        uint256 value, 
        bytes calldata data
    ) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(data);
        if (!success) revert MinimalAccount_CallFailded(result);
    }

    function _validateSignature(
        PackedUserOperation calldata userOp, 
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        if (_countValidSignatures(digest, userOp.signature) >= threshold) {
            return SIG_VALIDATION_SUCCESS;
        } else {
            return SIG_VALIDATION_FAILED;
        }
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        (bool success, ) = payable(msg.sender).call{value: missingAccountFunds}("");
        if (!success) revert MinimalAccount_PayPrefundFailded();
    }

    function getOwners() external view returns (address[] memory) {
        return s_owners;
    }

    function _initializeOwners(address[] memory owners, uint256 _threshold) internal {
        if (owners.length == 0 || _threshold == 0 || _threshold > owners.length) {
            revert MinimalAccount_InvalidThreshold();
        }

        for (uint256 i = 0; i < owners.length; i++) {
            address ownerAddr = owners[i];
            if (ownerAddr == address(0)) revert MinimalAccount_InvalidOwner();
            if (isOwner[ownerAddr]) revert MinimalAccount_DuplicateOwner();
            isOwner[ownerAddr] = true;
            s_owners.push(ownerAddr);
        }
        threshold = _threshold;
    }

    function _countValidSignatures(bytes32 digest, bytes calldata signatures) internal view returns (uint256) {
        if (signatures.length % 65 != 0) return 0;

        uint256 signatureCount = signatures.length / 65;
        address[] memory seenSigners = new address[](signatureCount);
        uint256 validCount;

        for (uint256 i = 0; i < signatureCount; i++) {
            bytes memory sig = new bytes(65);
            uint256 offset = i * 65;
            for (uint256 j = 0; j < 65; j++) {
                sig[j] = signatures[offset + j];
            }

            (address signer, ECDSA.RecoverError err,) = ECDSA.tryRecover(digest, sig);
            if (err != ECDSA.RecoverError.NoError) continue;
            if (!isOwner[signer]) continue;
            if (_alreadySeen(seenSigners, validCount, signer)) continue;

            seenSigners[validCount] = signer;
            validCount++;
        }

        return validCount;
    }

    function _alreadySeen(address[] memory seen, uint256 seenLength, address signer) internal pure returns (bool) {
        for (uint256 i = 0; i < seenLength; i++) {
            if (seen[i] == signer) return true;
        }
        return false;
    }

    receive() external payable {}

    fallback() external payable {}
}
