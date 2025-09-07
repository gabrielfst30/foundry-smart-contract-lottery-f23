//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    /// @title Create Subscription for Chainlink VRF
    /// @notice 1. Eu chamo o vrfCoordinator do helperConfig com a chainId correta
    /// @notice 2. Envio como parametro para a função que criará a subscription
    /// @notice 3. A função cria a subscription e retorna o Id

    /// @notice Create a subscription using the helper config contract
    /// @dev This function creates a subscription using the VRFCoordinator address from the helper config
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig(); // instanciando helperConfig
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator; // chamando getConfig() e retornando vrfCoordinator
        (uint256 subId, ) = createSubscription(vrfCoordinator); // chamando a função que criará a subscription
        return (subId, vrfCoordinator); // retornando o subId e o vrfCoordinator
    }

    /// @notice Create a subscription
    /// @dev This function creates a subscription using the VRFCoordinator address from the helper config
    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        console.log("Criando subscription na chain Id: ", block.chainid);
        console.log("Usando o VRFCoordinator: ", vrfCoordinator);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription(); // criando a subscription
        vm.stopBroadcast();

        console.log("Subscription criada com o Id: ", subId);
        console.log("Lembre-se de adicionar esse Id na sua HelperConfig.s.sol");
        return (subId, vrfCoordinator); // retornando o subId e o vrfCoordinator
    }

    /// @notice Run function to create a subscription
    function run() public {
        createSubscriptionUsingConfig();
    }
}

/// @title Fund Subscription for Chainlink VRF
/// @notice 1. Eu chamo o vrfCoordinator do helperConfig com a chain
/// @notice 2. Pego o subId da config
/// @notice 3. Pego o endereço do token LINK
/// @notice 4. Envio como parametro para a função que criará a subscription
/// @notice 5. A função cria a subscription e retorna o Id
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    // Fund a subscription using the helper config contract
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig(); // instanciando helperConfig
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator; // chamando getConfig() e retornando vrfCoordinator
        uint256 subId = helperConfig.getConfig().subscriptionId; // pegando o subId da config
        address linkToken = helperConfig.getConfig().link; // pegando o endereço do token LINK
        fundSubscription(vrfCoordinator, subId, linkToken); // chamando a função que criará a subscription
    }

    // Fund a subscription
    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address link
    ) public {
        console.log("Funding subscription na chain Id: ", block.chainid);
        console.log("Usando o subscriptionId: ", subscriptionId);
        console.log("Usando o VRFCoordinator: ", vrfCoordinator);
        console.log("Usando o LINK token: ", link);

        // Somente na chain local anvil, funde a subscription
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            ); // fundando a subscription
            vm.stopBroadcast();
        } else {
            // Na Sepolia ou outras testnets, transfira o LINK para a subscription
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    // Rodando a função para criar a subscription
    function run() public {
        fundSubscriptionUsingConfig();
    }
}

/// @title Add Consumer to Subscription for Chainlink VRF
/// @notice 1. Eu chamo o vrfCoordinator do helperConfig com a chain
/// @notice 2. Pego o subId da config
/// @notice 3. Envio como parametro para a função que adicionará o consumer
/// @notice 4. A função adiciona o consumer
/// @notice 5. O contrato consumer (Raffle) já está pronto para fazer requisições de aleatoriedade
contract AddConsumer is Script {
    /// @notice Add a consumer to the subscription using the helper config contract
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig(); // instanciando helperConfig
        uint256 subId = helperConfig.getConfig().subscriptionId; // pegando o subId da config
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator; // chamando getConfig() e retornando vrfCoordinator
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId); // chamando a função que adicionará o consumer
    }

    function addConsumer(address contractToAddtoVrf, address vrfCoordinator, uint256 subId) public {
        console.log("Adicionando consumer na chain Id: ", block.chainid);
        console.log("Usando o subscriptionId: ", subId);
        console.log("Usando o VRFCoordinator: ", vrfCoordinator);
        console.log("Adicionando o contrato: ", contractToAddtoVrf);
        vm.startBroadcast();
        // Adicionando o contrato consumer na subscription
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            contractToAddtoVrf
        ); // adicionando o consumer
        vm.stopBroadcast();
    }

    function run() external {
        // Pega o endereço do contrato Raffle mais recentemente implantado no blockchain (DevOpsTools - Cyfrin Updraft)
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

// Você precisa "fundear" (enviar LINK para) sua subscription do VRF Consumer porque o Chainlink VRF utiliza o saldo de LINK da subscription para pagar pelas requisições de aleatoriedade.

// Motivos principais:
// Sem LINK na subscription, o VRF não processa requests: o contrato VRFCoordinator verifica se há saldo suficiente antes de executar qualquer requisição.
// Cada chamada ao VRF consome uma quantidade de LINK, conforme definido na configuração do serviço.
// Se a subscription não estiver fundeada, seu contrato não conseguirá receber números aleatórios do Chainlink.
// Resumindo:
// A subscription precisa estar fundeada para garantir que o VRF funcione corretamente e seu contrato receba a aleatoriedade quando solicitado.

// O contrato/script Interactions.s.sol está dividido em duas partes:

// CreateSubscription:
// Cria automaticamente uma subscription VRF quando chamado (por exemplo, durante o deploy).

// FundSubscription:
// Fundeia (envia LINK para) a subscription, mas isso só acontece se você rodar o script específico para fundeamento. Ou seja, o fundeamento não é automático após a criação — você precisa executar o script de fundeamento separadamente.

// Resumindo:
// A criação da subscription é automática no deploy, mas o fundeamento precisa ser feito manualmente rodando o script FundSubscription.
