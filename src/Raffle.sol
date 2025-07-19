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

/**
 * @title Raffle Contract
 * @author Gabriel Santa Ritta
 * @notice Creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle {
    /** Errors */
    error Raffle__SendMoreToEnterRaffle(); //@dev error personalizado

    /** Events */
    event RaffleEntered(address indexed player);

    /** Variables */
    uint256 private immutable i_entranceFee; //@dev taxa de entrada
    uint256 private immutable i_interval; //@dev duração da lotéria em segundos
    //address[] precisa ser payable para que eu possa transferir ETH para o vencedor
    address payable[] private s_players; //@dev array de jogadores - storage variable
    uint256 private s_lastTimeStamp; //@dev timestamp inicial pós implementação de contrato

    // Inicializando com a taxa de entrada
    constructor(uint256 entraceFee, uint256 interval) {
        i_entranceFee = entraceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    // Entrar no sorteio
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        // Se não tiver valor minimo de taxa de entrada
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        //Adicionando quem entrou no sorteio a array s_players
        s_players.push(payable(msg.sender)); //msg.sender = address que interagiu com o contrato

        //emitindo um evento para quando o player entrar no sorteio
        emit RaffleEntered(msg.sender);
    }

    // Pegar vencedor
    /** 1. Pegar um número randomico
        2. Usar o número randomico to pick a player
        3. Chamar automáticamente 
    */
    function pickWinner() external {
        //@@dev timestamp atual - timestamp contarto < intervalo
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        //Pegue nosso random numer da Chainlink
    }

    /** Getter Functions */

    // Get taxa de entrada
    function getEntraceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
