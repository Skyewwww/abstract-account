// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "src/eth/MininalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployContract is Script {
    function deployMinimalAccount() public returns (HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getNetworkConfig();

        vm.startBroadcast(config.deployer);
        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);
        vm.stopBroadcast();

        return (helperConfig, minimalAccount);
    }
}