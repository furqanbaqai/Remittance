pragma solidity ^0.4.23;


/**
 * @title Contract for exchanging transactions from ether to 
 *        local currency.
 **/
contract Remittance{
    address public owner;
    bool public paused;
    
    event LogDoRemit(address indexed initiator, address receiver, bytes32 puzzle, uint amount);
    event LogAuthorizeTransaction(address indexed initiator, address originator, bytes32 puzzle, uint amount );
    event LogPause(address sender);
    event LogUnPause(address sender);
    
    
    struct Transaction{
        uint ethFunds; // Ether funds
        bytes32 puzzle; // keccak256 of the puzzle. Do i need this if i am keying with puzzle
        address sender; // sender address
        address receiver;
        bool processed;
        uint8 existFlag;
    }
    
    mapping(bytes32 => Transaction ) public transactions;
    
     /**
     * Modifier for checking if the procedure is called
     * by owner 
     */
    modifier ownerOnly{
        require(msg.sender == owner, "[ER101] Invalid owner address");
        _;
    }
    
    /**
     * Modifier to validate if contract is not paused
     */
    modifier whenNotPaused(){
        require(!paused, "[ER102] Contract is paused");
        _;
    }

    /**
     * Modifier to validate if the contract is paused
     */
    modifier whenPaused(){
        require(paused, "[ER103] Contract is not paused");
        _;
    }
    
    /**
     * Constructor for instantiating the contract
     */
    constructor() public{
        owner = msg.sender;
    }
    
    /**
     * Function for creating a remittance ccontract
     * @param otp1 First One Time Password
     * @param otp2 Sencond One Time Password
     * @param reciver Address of the receiver
     */
    function doRemit(bytes32 otp1, bytes32 otp2, address receiver) payable public whenNotPaused returns(bytes32 puzz){
        require(msg.value > 0, "[ER201] Invlaid value");
        bytes32 puzzle = keccak256(msg.sender,receiver,otp1,otp2); 
        require(transactions[puzzle].existFlag != 1, "[ER202] Invalid transaction");
        transactions[puzzle] = Transaction(msg.value, puzzle,msg.sender, receiver, false, 1);
        emit LogDoRemit(msg.sender, receiver,puzzle,msg.value);
        return puzzle;
    }
    
    /**
     * Function for withdrawing the money
     * @param First One Time Password
     * @param Sencond One Time Password
     * @originator Address of the originator
     **/
    function authorizeTransaction(bytes32 otp1, bytes32 otp2, address originator) public whenNotPaused returns(bool success){
        require(originator != address(0));
        bytes32 puzzle = keccak256(originator,msg.sender,otp1,otp2); // Explicitly genrating the puzzle
        require(transactions[puzzle].existFlag == 1, "[ER202] Invalid transaction");
        require(!transactions[puzzle].processed,"[ER203] Transaction processed");
        require(transactions[puzzle].receiver == msg.sender, "[ER204] Invalid Transaction Receiver");
        msg.sender.transfer(transactions[puzzle].ethFunds);
        transactions[puzzle].processed = true;
        emit LogAuthorizeTransaction(msg.sender, originator,puzzle,transactions[puzzle].ethFunds);
        return true;
    }
    
    /**
     * Procedure to pause the contract
     */
    function pause() ownerOnly whenNotPaused public{
        paused = true;
        emit LogPause(msg.sender);
    }

    /**
     * Procedure to unpause the contract
     */
    function unpause() ownerOnly whenPaused public{
        paused = false;
        emit LogUnPause(msg.sender);
    }
    
    
}