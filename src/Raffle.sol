// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//Importando VRF
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle Contract
 * @author Gabriel Santa Ritta
 * @notice Creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

//Herdando VRF
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle__SendMoreToEnterRaffle(); //@dev error personalizado
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState); // o erro mostrará o balance do contract, qtd de players e o estado do sorteio

    /**
     * Type Declarations
     */
    enum RaffleState {
        // Opções para o estado do sorteio
        OPEN, // 0
        CALCULATING // 1
    }

    /**
     * State Variables
     */
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // request de confirmações VRF Chainlink
    uint32 private constant NUM_WORDS = 1; // num_words VRF Chainlink
    uint256 private immutable i_entranceFee; // @dev taxa de entrada
    uint256 private immutable i_interval; // @dev duração da lotéria em segundos
    bytes32 private immutable i_keyHash; // keyHash VRF Chainlink
    uint256 private immutable i_subscriptionId; // subs VRF Chainlink
    uint32 private immutable i_callbackGasLimit;
    // address[] precisa ser payable para que eu possa transferir ETH para o vencedor
    address payable[] private s_players; // @dev array de jogadores - storage variable
    uint256 private s_lastTimeStamp; // @dev timestamp inicial pós implementação de contrato
    address private s_recentWinner; // vencedor recente
    RaffleState private s_raffleState; // variável do estado de sorteio com tipo enum

    /**
     * Events
     */
    event RaffleEntered(address indexed player); // event para quando um player entrar no sorteio
    event WinnerPicker(address indexed winner); // event para quando o vencedor for escolhido
    event RequestRaffleWinner(uint256 indexed requestId); // event para quando o request for enviado para o VRF

    // Inicializando com a taxa de entrada
    // Retornando address do VRF
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane, // keyHash VRF Chainlink
        uint256 subscriptionId, // subs VRF Chainlink
        uint32 callbackGasLimit // gas limit VRF Chainlink
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    // Entrar no sorteio
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        // Se não tiver valor minimo de taxa de entrada
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        // só entra no sorteio se o estado estiver OPEN
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        // Adicionando quem entrou no sorteio a array s_players
        s_players.push(payable(msg.sender)); //msg.sender = address que interagiu com o contrato

        // emitindo um evento para quando o player entrar no sorteio
        emit RaffleEntered(msg.sender);
    }

    // Pegar vencedor
    /**
     * 1. Pegar um número randomico
     *     2. Usar o número randomico to pick a player
     *     3. Chamar automáticamente
     */

    /**
     * Chainlink Automation
     * Quando é a hora de pegar um vencedor?
     * @dev Essa é a função que os nodes da Chainlink irá chamar quando o sorteio estiver pronto
     * para pegar um player vencedor
     * As condições abaixo em ordem deve ser true para que upkeepNeeded seja true:
     *   1. O intervalo de tempo entre as execuções do sorteio passou.
     *   2. O sorteio deve estar aberto
     *   3. O contrato tem ETH (has players)
     *   4. Implicitamente sua subscription tem LINK
     * @param - ignored
     * @return upkeepNeeded - se for true, restart no sorteio
     */
    function checkUpkeep(bytes memory /*checkdata*/ ) // checando se o upkeep é necessário
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        //condições
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval); // timestamp atual - ultimo timestamp contrato >= intervalo
        bool isOpen = s_raffleState == RaffleState.OPEN; // Verifica se o sorteio esta aberto
        bool hasBalance = address(this).balance > 0; // Verifica se existe balance
        bool hasPlayer = s_players.length > 0; // Verifica se tem players
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayer; // adicionando condições para upkeepNeed rodar caso todas sejam true
        return (upkeepNeeded, ""); //retornando valores esperados na função
    }

    // Será automaticamente chamada
    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep(""); //checando se o upkeep é necessário

        // Revertendo se o upkeep não for necessário
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        // setando novo estado do sorteio
        s_raffleState = RaffleState.CALCULATING;

        // Pegue nosso random number da Chainlink
        // 1. Estruturando request
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        // 2. Enviando request para o coordinator VRF e armazenando o requestId
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestRaffleWinner(requestId); // emitindo um event do requestId
    }

    // 3. Get VRF após request (callback)
    // Recebe o requestID e retorna randomWords
    function fulfillRandomWords(uint256, /*requestId*/ uint256[] calldata randomWords) internal override {
        // Checks

        // Lógica explicada
        // s_players = 10 <- tenho 10 players
        // rng = 1223123123  <- recebo um número random
        // 1223123123 % 10 = 2 <- faço uma operação de módulo, o resultado que é o resto dessa divisão, será o número do vencedor.

        // Effect (Internal Contract States Changes)
        uint256 indexOfWinner = randomWords[0] % s_players.length; // randomWords % módulo de s_players.lenght -> valor
        address payable recentWinner = s_players[indexOfWinner]; // s_players recebe o valor aleatorio e escolhe um player na array
        s_recentWinner = recentWinner; // setando o último vencedor
        s_raffleState = RaffleState.OPEN; // abrindo sorteio após a definição de um novo vencedor
        s_players = new address payable[](0); // limpando array de jogadores
        s_lastTimeStamp = block.timestamp; // recomeçando intervalo
        emit WinnerPicker(s_recentWinner); //emitindo um event do último vencedor

        // Interactions (External Contract Interactions)
        (bool success,) = recentWinner.call{value: address(this).balance}(""); // pagando o último vencedor com o valor armazenado no contrato
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */

    // Get taxa de entrada
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    // Get raffle state
    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    // Get player por index
    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index]; // retornando o address do player na posição index
    }

    // Get último timestamp
    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    // Get do último vencedor
    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
