// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "src/eth/MininalAccount.sol";
import {DeployContract} from "script/DeployContract.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
 
contract MinimalAccountTest is Test {
    uint256 constant INITIAL_AMOUNT = 100 ether;
    MinimalAccount minimalAccount;
    HelperConfig config;
    ERC20Mock token;

    function setUp() public {
        DeployContract deploy = new DeployContract();
        (config, minimalAccount) = deploy.deployMinimalAccount();
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

        vm.prank(config.getNetworkConfig().deployer);
        minimalAccount.execute(dest, value, data);

        assertEq(token.balanceOf(address(minimalAccount)), INITIAL_AMOUNT);
    }
}