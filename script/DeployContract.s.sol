// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "src/eth/MininalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployContract is Script {
    function deployMinimalAccount() public returns (HelperConfig.NetworkConfig memory, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getNetworkConfig();
        address[] memory owners = new address[](1);
        owners[0] = config.deployer;

        vm.startBroadcast(config.deployer);
        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint, owners, 1);
        vm.stopBroadcast();

        return (config, minimalAccount);
    }
}
