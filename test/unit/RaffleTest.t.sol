//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee; // Taxa de entrada para participar
    uint256 interval; // Intervalo entre sorteios
    address vrfCoordinator; // Endereço do coordenador VRF da Chainlink
    bytes32 gasLane; // KeyHash para o VRF (define o preço do gás)
    uint256 subscriptionId; // ID da assinatura VRF
    uint32 callbackGasLimit; // Limite de gás para o callback VRF

    address PLAYER = makeAddr("player"); // cheatcode para criar um address
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether; // balance inicial

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event WinnerPicker(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle(); // instanciando contrato de deploy
        (raffle, helperConfig) = deployer.deployContract(); // deployando e retornando raffle e helperConfig
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // pegando a network config

        // Setando variáveis do vrf
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE); // dando balance inicial para o PLAYER
    }

    // testando se o raffle inicializará com estado OPEN
    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN); // verificando se o RaffleState esta OPEN
    }

    /// @title Enter Raffle 👇

    /// @dev Reverte se o jogador não pagar o suficiente
    function testRaffleRevertWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER

        // Act & Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector); // esperando o revert com o erro especifico
        raffle.enterRaffle(); // chamando a função que deve reverter
    }

    /// @dev Testa se o jogador é adicionado ao array de jogadores ao entrar
    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER

        // Act
        raffle.enterRaffle{value: entranceFee}(); // pagando a taxa de entrada
        console.log("Entrance Fee:", entranceFee);

        // Assert
        address playerRecorded = raffle.getPlayer(0); // pegando o jogador na posição 0
        assert(playerRecorded == PLAYER); // verificando se o jogador na posição 0 é o PLAYER
    }

    /// @dev Testa se o evento é emitido quando um jogador entra no sorteio
    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER

        // Act
        vm.expectEmit(true, false, false, false, address(raffle)); // esperando o evento ser emitido
        emit RaffleEntered(PLAYER); // // o evento espera que o PLAYER seja o address

        //Assert
        raffle.enterRaffle{value: entranceFee}(); // pagando a taxa de entrada
    }

    /// @dev Testa se não é possível entrar no sorteio quando o contrato está no estado CALCULATING.
    function testCantEnterWhenRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER
        raffle.enterRaffle{value: entranceFee}(); // pagando a taxa de entrada
        vm.warp(block.timestamp + interval + 1); // avançando o tempo
        vm.roll(block.number + 1); // avançando o bloco
        raffle.performUpkeep(""); // checando se o upkeep é necessário

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector); // esperando o revert com o erro especifico
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER
        raffle.enterRaffle{value: entranceFee}(); // envia a transação que deve reverter quando o raffle está em CALCULATING
    }

    /// @dev Testa se o upkeep retorna falso quando não houver balance suficiente.
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1); // avançando o tempo
        vm.roll(block.number + 1); // avançando o bloco

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // checando se o upkeep é necessário

        // Assert
        assert(!upkeepNeeded); // verificando se o upkeep não é necessário (é falso)
    }

    /// @dev Testa se o upkeep retorna falso quando o sorteio não está aberto.
    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public {
        // Arrange
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER
        raffle.enterRaffle{value: entranceFee}(); // pagando a taxa de entrada
        vm.warp(block.timestamp + interval + 1); // avançando o tempo
        vm.roll(block.number + 1); // avançando o bloco
        raffle.performUpkeep(""); // chamando a função performUpkeep

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // checando se o upkeep é necessário

        // Assert
        assert(!upkeepNeeded); // verificando se o upkeep não é necessário (é falso)
    }

    /// @dev Testa se o upkeep retorna falso quando o tempo suficiente passou
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasPassed() public {
        // Arrange
        vm.warp(block.timestamp + interval - 1); // tempo insuficiente passou (1 segundo a menos que o necessário)
        vm.roll(block.number + 1); // avança o bloco

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // checando se o upkeep é necessário

        // Assert
        assert(!upkeepNeeded); // deve ser falso pois o tempo não passou
    }

    /// @dev Testa se o upkeep retorna verdadeiro quando todas as condições forem atendidas.
    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Arrange
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER
        raffle.enterRaffle{value: entranceFee}(); // pagando a taxa de entrada
        vm.warp(block.timestamp + interval + 1); // avançando o tempo
        vm.roll(block.number + 1); // avançando o bloco
        address playerRecorded = raffle.getPlayer(0); // pegando o jogador na posição 0

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // checando se o upkeep é necessário
        console.log("Upkeep Needed:", upkeepNeeded);
        // Assert
        assert(playerRecorded == PLAYER); // verificando se a quantidade de players é maior que 0
        assert(upkeepNeeded); // deve ser verdadeiro pois todas as condições foram atendidas
    }

    ///@dev Testa que o PerformUpkeep só pode ser chamado se o checkUpkeep retornar verdadeiro.
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER
        raffle.enterRaffle{value: entranceFee}(); // pagando a taxa de entrada
        vm.warp(block.timestamp + interval + 1); // avançando o tempo
        vm.roll(block.number + 1); // avançando o bloco

        // Act / Assert
        raffle.performUpkeep(""); // chamando a função performUpkeep
    }

    /// @dev Testa se o PerformUpkeep reverte quando o upkeep não é necessário.
    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0; // saldo atual
        uint256 numPlayers = 0; // número de jogadores
        Raffle.RaffleState rState = raffle.getRaffleState(); // estado atual do sorteio

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                uint256(rState)
            )
        ); // esperando o revert na proxima linha chamando o erro especifico passando os parametros esperados.
        raffle.performUpkeep(""); // chamando a função performUpkeep
    }

    /// @dev Modificador para entrar no sorteio e avançar o tempo
    modifier raffleEnteredAndTimePassed() {
        // Arrange
        vm.prank(PLAYER); // definindo o próximo tx como vinda do PLAYER
        raffle.enterRaffle{value: entranceFee}(); // pagando a taxa de entrada
        vm.warp(block.timestamp + interval + 1); // avançando o tempo
        vm.roll(block.number + 1); // avançando o bloco
        _;
    }

    /// @dev Testa se o performUpkeep atualiza o estado do sorteio, emite um request ID e chama o VRFCoordinator.
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEnteredAndTimePasse {
        /// @Note o requestId tem que retornar maior que 0 e o estado do sorteio deve ser CALCULATING
      
        // Act
        vm.recordLogs(); // começando a gravar os logs, quaisquer eventos emitidos serão gravados a partir daqui.
        raffle.performUpkeep(""); // chamando a função performUpkeep
        Vm.Log[] memory entries = vm.getRecordedLogs(); // pegando os logs gravados
        bytes32 requestId = entries[1].topics[1]; // pegando o requestId do evento emitido, nosso evento acontecerá depois do coordinator VRF.

        // Assert
        Raffle.RaffleState rState = raffle.getRaffleState(); // pegando o estado atual do sorteio
        assert(uint256(requestId) > 0); // verificando se o requestId é maior que 0
        assert(uint256(rState) == 1); // verificando se o estado do sorteio é CALCULATING
    }
}
