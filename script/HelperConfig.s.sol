// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address entryPoint;
        address deployer;
    }

    uint256 constant LOCAL_CHAIN_ID = 31337;
    uint256 constant ETH_SEP_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEP_CHAIN_ID = 300;
    address constant ANVIL_DEFAULT_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant DEPLOYER = 0xfa0d8ebcA31a1501144A785a2929e9F91b0571d0;
    
    mapping (uint256 => NetworkConfig) public networkConfigs;

    error HelperConfig__InvalidChainId();

    constructor() {
        networkConfigs[LOCAL_CHAIN_ID] = getLocalConfig();
        networkConfigs[ETH_SEP_CHAIN_ID] = NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            deployer: DEPLOYER
        });
        networkConfigs[ZKSYNC_SEP_CHAIN_ID] = NetworkConfig({
            entryPoint: address(0),
            deployer: DEPLOYER
        });
    }

    function getLocalConfig() public returns (NetworkConfig memory) {
        EntryPoint entryPoint = new EntryPoint();
        networkConfigs[LOCAL_CHAIN_ID] = NetworkConfig({
            entryPoint: address(entryPoint),
            deployer: ANVIL_DEFAULT_DEPLOYER
        });
        return networkConfigs[LOCAL_CHAIN_ID];
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return getNetworkConfigByChainId(block.chainid);
    }

    function getNetworkConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].entryPoint != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }
}