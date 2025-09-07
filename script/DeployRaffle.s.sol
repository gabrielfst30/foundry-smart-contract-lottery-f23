//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";

import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/Interactions.s.sol";
import {FundSubscription, AddConsumer} from "script/Interactions.s.sol";
contract DeployRaffle is Script {
    function run() public {
        deployContract(); // chamando a função que fará o deploy
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // instanciando helperConfig
        // local -> deploy mocks, pega local config
        // sepolia -> pega sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // chamando getConfig() que trará nosso block.chainid

        // se o subscriptionId for 0, cria uma subscription nova (serve para podermos fazer testes locais)
        if(config.subscriptionId == 0){
            CreateSubscription subscriptionContract = new CreateSubscription(); // instanciando o contrato que criará a subscription
            (config.subscriptionId, config.vrfCoordinator) = subscriptionContract.createSubscription(config.vrfCoordinator); // criando a subscription passando o vrfCoordinator do config
            // Acima, retornamos o subId e o vrfCoordinator e setamos na nossa config
        
        // Fund a subscription se for local
        FundSubscription fundSubscription = new FundSubscription(); // instanciando o contrato que criará a subscription
        fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link); // fundando a subscription)
        }

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

        AddConsumer addConsumer = new AddConsumer(); // instanciando o contrato que adicionará o consumer
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId); // adicionando o consumer

        return (raffle, helperConfig);
    }
}
