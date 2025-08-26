//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";

import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployRafflle is Script {
    function run() public {}

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // instanciando helperConfig
        // local -> deploy mocks, pega local config
        // sepolia -> pega sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // chamando getConfig() que trará nosso block.chainid

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
