// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
​
// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions
​
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
    uint256 private immutable i_entranceFee; //taxa de entrada

    //Inicializando com a taxa de entrada
    constructor(uint256 entraceFee){
        i_entranceFee = entraceFee;
    }

    //Entrar no sorteio
    function enterRaffle() public payable {}

    //Pegar vencedor
    function pickWinner() public {}

    /** Getter Functions */

    //Get taxa de entrada
    function getEntraceFee() external view returns(uint256){
        return i_entranceFee;
    }

    
}