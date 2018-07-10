pragma solidity ^0.4.23;

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/lifecycle/Pausable.sol";


/**
 * @title Contract for exchanging transactions from ether to 
 *        local currency.
 **/
contract Remittance is Pausable {
    using SafeMath for uint;
    
    event LogDoRemit(address indexed initiator, address receiver, bytes32 puzzle, uint amount);
    event LogAuthorizeTransaction(address indexed initiator, address originator, bytes32 puzzle, uint amount );
    event LogPause(address sender);
    event LogUnPause(address sender);
    
    
    struct Transaction{
        uint ethFunds; // Ether funds
        bytes32 puzzle; // keccak256 of the puzzle. Do i need this if i am keying with puzzle
        address sender; // sender address
        address receiver;
    }
    
    mapping(bytes32 => Transaction ) public transactions;
    
    /**
     * Constructor for instantiating the contract
     */
    constructor() public{
        owner = msg.sender;
    }
    
    /**
     * @dev Function for creating a remittance ccontract
     * @param otp1 First One Time Password
     * @param otp2 Sencond One Time Password
     * @param receiver Address of the receiver
     */
    function doRemit(bytes32 otp1, bytes32 otp2, address receiver) payable public whenNotPaused returns(bytes32 puzz){
        require(msg.value > 0, "[ER201] Invlaid value");
        bytes32 puzzle = encodePuzzle(msg.sender,receiver,otp1,otp2); 
        require(transactions[puzzle].ethFunds <= 0, "[ER202] Invalid transaction");
        transactions[puzzle] = Transaction(msg.value, puzzle,msg.sender, receiver);
        emit LogDoRemit(msg.sender, receiver,puzzle,msg.value);
        return puzzle;
    }
    
    /**
     * @dev Procedure for authorizing the transaction     
     * @param otp1 First One Time Password
     * @param otp2 Sencond One Time Password
     * @param originator Address of the originator
     **/
    function authorizeTransaction(bytes32 otp1, bytes32 otp2, address originator) public whenNotPaused returns(bool success){
        require(originator != address(0));
        bytes32 puzzle = encodePuzzle(originator,msg.sender,otp1,otp2); // Explicitly genrating the puzzle
        require(transactions[puzzle].receiver == msg.sender, "[ER204] Invalid Transaction Receiver");
        require(transactions[puzzle].ethFunds > 0, "[ER204] Invalid Transaction Receiver");
        uint fundsToTransfer = transactions[puzzle].ethFunds;
        delete transactions[puzzle];
        emit LogAuthorizeTransaction(msg.sender, originator,puzzle,transactions[puzzle].ethFunds);
        msg.sender.transfer(fundsToTransfer);                
        return true;
    }
    
    /**
     * Function for 
     **/
    function encodePuzzle(address sender, address receiver, bytes32 otp1, bytes32 otp2) private pure returns(bytes32 puzzle){
        return keccak256(abi.encodePacked(sender,receiver,otp1,otp2));
    }
    
    
}