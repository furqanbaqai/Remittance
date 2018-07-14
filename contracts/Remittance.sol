pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";

/** Note: Require in Remix
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol"; 
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/lifecycle/Pausable.sol"; 
 */

/**
 * @title Contract for exchanging transactions from ether to 
 *        local currency.
 **/
contract Remittance is Pausable {
    using SafeMath for uint256;
    
    event LogSendRemitance(bytes32 transKey, address indexed initiator, address indexed receiver, uint amount, uint expireson);
    event LogClaimRemittance(address indexed initiator, uint amount );
    event LogClaimRturns(address indexed initiator, uint amount, uint expiresOn );

    
    struct Transaction{
        uint ethFunds; // Ether funds        
        address sender; // sender address
        address receiver; // receiver address
        uint expiresOn; // expires on
        bool processed;                
    }
    
    mapping(bytes32 => Transaction ) public transactions;
    
    /**
     * Constructor for instantiating the contract
     */
    constructor() public{        
    }
    
    /**
     * @dev Function for creating a remittance ccontract
     * @param transKey  transKey which will be genrated off-chain by calling hashHelper() function
     * @param receiver  Address of the receiver     
     */
    function sendRemitance(bytes32 transKey, address receiver) payable public whenNotPaused returns(bool success){
        require(msg.value > 0, "[ER201] Invlaid Ether value");
        require(msg.sender != receiver, "[ER203] Remitter can not be the receiver");        
        require(transactions[transKey].ethFunds == 0, "[ER202] Invalid transaction"); // same password already used
        require(!transactions[transKey].processed,"[ER204] Invliad Trnsaction");
        uint expiresOn = block.timestamp + 50 days; // Transaction is valid till 50 days
        transactions[transKey] = Transaction( msg.value, msg.sender, receiver, expiresOn, false);
        emit LogSendRemitance(transKey,msg.sender, receiver,msg.value,expiresOn);
        return true;
    }
    
    /**
     * @dev Procedure for claiming remittance
     * @param otp1 First OTP exchange with the receiver / Bob
     * @param otp2 Seconf OTP exchanged with the exchange house / Carol
     * @param payID Payment ID OR Voucher number
     * @return success true in-case of successfull registration of the transaction
     **/
    function claimRemittance(bytes32 otp1, bytes32 otp2, bytes32 payID ) public whenNotPaused returns(bool success){        
        bytes32 transKey = hashHelper(msg.sender,otp1, otp2, payID);
        require(transactions[transKey].receiver == msg.sender, "[ER204] Invalid Transaction Receiver");
        require(transactions[transKey].ethFunds > 0, "[ER204] Invalid Transaction Receiver");
        require(!transactions[transKey].processed,"[ER204] Invliad Trnsaction");        
        uint expiresOn = block.timestamp + 50 days; 
        require(transactions[transKey].expiresOn < expiresOn,"[ER210] Transaction expired");
        uint fundsToTransfer = transactions[transKey].ethFunds;
        transactions[transKey].processed = true;
        transactions[transKey].ethFunds = 0;
        emit LogClaimRemittance(msg.sender, transactions[transKey].ethFunds);        
        msg.sender.transfer(fundsToTransfer);                  
        return true;
    }
    
    
    /**
     * @dev Procedure for returning funds to the sende in-case it is expired
     * @param otp1 First OTP exchange with the receiver / Bob
     * @param otp2 Seconf OTP exchanged with the exchange house / Carol
     * @param payID Payment ID OR Voucher number
     * @return success true in-case of successfull registration of the transaction
     **/
    function claimReturns(bytes32 otp1, bytes32 otp2, bytes32 payID) public whenNotPaused returns(bool success){
        bytes32 transKey = hashHelper(msg.sender,otp1, otp2, payID);
        require(transactions[transKey].sender == msg.sender, "[ER206] Invalid address received");
        require(transactions[transKey].processed,"[ER207] Transaction is under process");
        require(transactions[transKey].ethFunds > 0, "[ER204] Invalid Transaction Receiver");
        uint expiresOn = block.timestamp + 50 days; // Transaction is valid till 50 days
        require(transactions[transKey].expiresOn >= expiresOn,"Transaction is not expired");
        uint fundsTransmit = transactions[transKey].ethFunds;
        transactions[transKey].ethFunds = 0;
        emit LogClaimRturns(msg.sender, fundsTransmit, transactions[transKey].expiresOn );
        msg.sender.transfer(fundsTransmit);                  
        return true;
    }
    
    /**
     * Function for encoding puzzle sent
     * @param receiver Receiver address
     * @param otp1 First OTP exchange with the receiver / Bob
     * @param otp2 Seconf OTP exchanged with the exchange house / Carol
     * @param payID Payment ID OR Voucher number
     * @return success true in-case of successfull registration of the transaction
     **/
    function hashHelper(address receiver, bytes32 otp1, bytes32 otp2, bytes32 payID) public pure returns(bytes32 puzzle){
        return keccak256(abi.encodePacked(receiver,otp1, otp2, payID));
    }
    
    
}