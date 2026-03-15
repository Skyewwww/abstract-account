// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {MinimalAccount} from "src/eth/MininalAccount.sol";
import {DeployContract} from "script/DeployContract.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {SendPackedUserOp} from "script/SendPackedUserOp.s.sol";

contract MinimalAccountTest is Test {

    uint256 constant INITIAL_AMOUNT = 100 ether;

    MinimalAccount minimalAccount;
    SendPackedUserOp sendPackedUserOp;
    HelperConfig.NetworkConfig config;
    ERC20Mock token;

    address user = vm.addr(0x123);

    function setUp() public {
        DeployContract deploy = new DeployContract();
        (config, minimalAccount) = deploy.deployMinimalAccount();
        sendPackedUserOp = new SendPackedUserOp();
        token = new ERC20Mock();
    }

    function testOwnerCanExecute() public {
        address dest = address(token);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            INITIAL_AMOUNT
        );

        vm.prank(config.deployer);
        minimalAccount.execute(dest, value, data);

        assertEq(token.balanceOf(address(minimalAccount)), INITIAL_AMOUNT);
    }

    function testValiateUserOp() public {
        address dest = address(token);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            INITIAL_AMOUNT
        );
        bytes memory callData = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            dest,
            value,
            data
        );
        address sender = config.deployer;

        PackedUserOperation memory userOp = sendPackedUserOp.generateSignedUserOp(sender, callData, config);
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        uint256 missingAccountFunds = 1 ether;

        vm.deal(address(minimalAccount), INITIAL_AMOUNT);
        vm.prank(config.entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(
            userOp,
            userOpHash,
            missingAccountFunds
        );

        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteUserOp() public {
        address dest = address(token);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            INITIAL_AMOUNT
        );
        bytes memory callData = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            dest,
            value,
            data
        );
        // Sender must be the deployed account contract (EntryPoint checks this)
        address sender = address(minimalAccount);

        PackedUserOperation memory userOp = sendPackedUserOp.generateSignedUserOp(sender, callData, config);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;
        
        vm.deal(address(minimalAccount), INITIAL_AMOUNT);
        // EntryPoint nonReentrant guard expects tx.origin == msg.sender (EOA caller)
        vm.prank(user, user);
        IEntryPoint(config.entryPoint).handleOps(ops, payable(user));

        assertEq(token.balanceOf(address(minimalAccount)), INITIAL_AMOUNT);
    }
}