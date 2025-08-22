//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
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
            getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    // SEPOLIA
    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, //1e16
                interval: 30, //30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, //500 gwei hash-SepoliaTestnet
                callbackGasLimit: 500000, //500,000 gas
                subscriptionId: 0
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
    }
}
