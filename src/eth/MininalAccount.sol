// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is Ownable, IAccount {
    IEntryPoint public immutable entryPoint;

    error MinimalAccount_NotFromEntryPoint();
    error MinimalAccount_NotFromEntryPointOrOwner();
    error MinimalAccount_CallFailded(bytes data);

    modifier requireFromEntryPoint {
        if (msg.sender != address(entryPoint)) revert MinimalAccount_NotFromEntryPoint();
        _;
    }

    modifier requireFromEntryPointOrOwner {
        if (msg.sender != address(entryPoint) && msg.sender != owner()) {
            revert MinimalAccount_NotFromEntryPointOrOwner();
        }
        _;
    }

    constructor(address _entryPoint) Ownable(msg.sender) {
        entryPoint = IEntryPoint(_entryPoint);
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {

    }
    
    function execute(
        address dest, 
        uint256 value, 
        bytes calldata data
    ) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(data);
        if (!success) revert MinimalAccount_CallFailded(result);
    }

    receive() external payable {}

    fallback() external payable {}
}