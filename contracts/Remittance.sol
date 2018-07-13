pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";


/**
 * @title Contract for exchanging transactions from ether to 
 *        local currency.
 **/
contract Remittance is Pausable {
    using SafeMath for uint256;
    
    event LogSendRemitance(address indexed initiator, address receiver, uint amount, bytes32 paymentID, uint expireson);
    event LogClaimRemittance(address indexed initiator, uint amount );

    
    struct Transaction{
        uint ethFunds; // Ether funds
        bytes32 puzzle; // keccak256 of the puzzle. Do i need this if i am keying with puzzle
        address sender; // sender address
        address receiver; // receiver address
        uint expiresOn; // expires on
        bool processed; // Processed
        uint returnFunds; // Returned funds
    }
    
    mapping(bytes32 => Transaction ) public transactions;
    
    /**
     * Constructor for instantiating the contract
     */
    constructor() public{        
    }
    
    /**
     * @dev Function for creating a remittance ccontract
     * @param pass      Password comign off-chain
     * @param receiver  Address of the receiver
     * @param payID     Payment ID, should be calculated off-chain
     */
    function sendRemitance(bytes32 pass, address receiver, bytes32 payID) payable public whenNotPaused returns(bool success){
        require(msg.value > 0, "[ER201] Invlaid Ether value");
        require(msg.sender != receiver, "[ER203] Remitter can not be the receiver");
        bytes32 hashedPass = hashHelper(receiver,pass);
        require(transactions[payID].ethFunds == 0, "[ER202] Invalid transaction"); // same password already used
        require(!transactions[payID].processed,"[ER204] Invliad Trnsaction");
        uint expiresOn = block.timestamp + 50 days; // Transaction is valid till 50 days
        transactions[payID] = Transaction(msg.value, hashedPass,msg.sender, receiver, expiresOn, false,0);
        emit LogSendRemitance(msg.sender, receiver,msg.value, payID,expiresOn);
        return true;
    }
    
    /**
     * @dev Procedure for claiming remittance
     * @param pass  Hashed password coming from off-chain
     * @param payID Payment iD should be calculated off-chain
     **/
    function claimRemittance(bytes32 pass,bytes32 payID) public whenNotPaused returns(bool success){
        bytes32 hashedPass = hashHelper(msg.sender,pass); // Explicitly generating the puzzle
        require(transactions[payID].receiver == msg.sender, "[ER204] Invalid Transaction Receiver");
        require(transactions[payID].ethFunds > 0, "[ER204] Invalid Transaction Receiver");
        require(transactions[payID].puzzle == hashedPass, "[ER205] Invalid password");
        require(!transactions[payID].processed,"[ER204] Invliad Trnsaction");
        require(transactions[payID].returnFunds == 0, "[ER209] Suspected Transaction");
        uint expiresOn = block.timestamp + 50 days; 
        if(transactions[payID].expiresOn > expiresOn ){
            transactions[payID].returnFunds = transactions[payID].ethFunds;
            transactions[payID].ethFunds = 0;
            transactions[payID].processed = true;
            return false;
        }else{
            uint fundsToTransfer = transactions[payID].ethFunds;
            /* Rather than deleting the structure, we will keep the reference */
            transactions[payID].ethFunds = 0;
            transactions[payID].processed = true;
            emit LogClaimRemittance(msg.sender, transactions[payID].ethFunds);
            msg.sender.transfer(fundsToTransfer);                  
            return true;
        }
    }
    
    
    /**
     * @dev Procedure for returning funds to the sende in-case it is expired
     * @param pass      password of the transactions
     * @param payID     payment ID
     * @param receiver  Address of the receiver
     **/
    function claimReturns(bytes32 pass, address receiver, bytes32 payID) public whenNotPaused returns(bool success){
        bytes32 hashedPass = hashHelper(receiver,pass); // Explicitly generating the puzzle
        require(transactions[payID].sender == msg.sender, "[ER206] Invalid address received");
        require(transactions[payID].puzzle == hashedPass, "[ER205] Invalid password");
        require(transactions[payID].processed,"[ER207] Transaction is under process");
        require(transactions[payID].returnFunds > 0, "[ER208] Nothing to return");
        msg.sender.transfer(transactions[payID].returnFunds);                  
        return true;
    }
    
    /**
     * Function for encoding puzzle sent
     **/
    function hashHelper(address receiver, bytes32 hashedPass) public pure returns(bytes32 puzzle){
        return keccak256(abi.encodePacked(receiver,hashedPass));
    }
    
    
}