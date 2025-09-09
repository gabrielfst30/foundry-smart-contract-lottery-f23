//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /* VRF Mock Values (variáveis esperadas no param do VRF mock)*/
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH PRICE
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee; // Taxa de entrada para participar
        uint256 interval; // Intervalo entre sorteios
        address vrfCoordinator; // Endereço do coordenador VRF da Chainlink
        bytes32 gasLane; // KeyHash para o VRF (define o preço do gás)
        uint256 subscriptionId; // ID da assinatura VRF
        uint32 callbackGasLimit; // Limite de gás para o callback VRF
        address link; // endereço do token LINK
        address account; // endereço da conta que deploya o contrato
    }

    NetworkConfig public localNetworkConfig; // config para rede local
    mapping(uint256 chainId => NetworkConfig) public networkConfigs; //chainId será a key para cada network config

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        // Se existir um vrfCoordinator no chainId escolhido retorne o chainId.
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId]; //retornando a chainId escolhida
            // Caso não exista um vrfCoordinator retorne a Chain Local
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    // retorna uma network config
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid); //retorna a chainid baseada na validação da função getConfigByChainId
    }

    // SEPOLIA
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, //1e16
                interval: 30, //30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, //500 gwei hash-SepoliaTestnet
                callbackGasLimit: 500000, //500,000 gas
                subscriptionId: 38430831831527318227116343036273060316526555870930394361740204325440722928645,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789, // endereço do token LINK na Sepolia
                // Para usar o VRF, você precisa pagar as requisições com LINK. O contrato VRFCoordinator consome LINK do saldo da subscription.
                account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
            });
    }

    // Get or Create Anvil Network Config
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Se ja estivermos configurado uma rede local anvil, retornamos a config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        // Deployando VRFCoordinator mockado da chainlink
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        LinkToken link = new LinkToken(); // deployando o token link mockado
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether, //1e16
            interval: 30, //30 seconds
            vrfCoordinator: address(vrfCoordinatorMock), // pegando o address do mock
            gasLane: 0, // pode ser qualquer coisa, não importa pq é mockado.
            callbackGasLimit: 500000, //500,000 gas
            subscriptionId: 0,
            link: address(link), // endereço do token LINK mockado
            account: msg.sender // endereço da conta que deploya o contrato
        });

        return localNetworkConfig;
    }
}
