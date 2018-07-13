/**
 * Unit Test Case for testing Remittance contract
 */

var Remittance = artifacts.require("./Remittance.sol");
var remittanceCont;

contract('Remittance', function (accounts) {
    var carolAccount = web3.eth.accounts[0]; // Carol is the owner of the exchange house;
    var aliceAccount = web3.eth.accounts[1];
    var bobAccount = web3.eth.accounts[2];         
    before(function (done) {                        

        remittanceCont = Remittance.new({
            from: carolAccount,
            gas: 3000000,
            gasvalue: 1
        });
        done();
    });
    /* Unit Test Case# 01: Check if contract was instanciated */
    xit("[UT01] Check if the instance exist", function(done){
        assert(typeof (remittanceCont), "object", "[UT001] Failure: Invalid object");
        done();
    });    
    /* Unit test Case# 02: Check if the owner is carol / account[0] */
    xit("[UT02] Owner should  Carol", function(done){
        // Assumption: alice have enough money
        remittanceCont.then(instance => {
            instance.owner.call();
        }).then(owner => {
            assert(owner == carolAccount, "[UT02] Invalid Owner ID "+owner);
            done();
        });        
    });
    /* Unit Test Case# 03: Send remittance transaction of 50wei from alice to bob */
    it("[UT03] Send Remittance transaction of 50wei from alice to bob", function(done){        
        remittanceCont.then(instance => {
            // Get alice and bob's balances
            var contractBalance;
            var aliceBalance;
            var pass;
            var payID;
            contractBalance = web3.eth.getBalance(instance.address).toNumber();
            aliceBalance = web3.eth.getBalance(aliceAccount).toNumber();            
            pass = web3.sha3("991745", {encode: 'hex'});        
            payID = web3.sha3(pass+web3.eth.blockNumber, {encode: 'hex'});
            instance.sendRemitance(pass,carolAccount,payID,{from: aliceAccount, value: 500}).then(txHash =>{
                newContBalance = web3.eth.getBalance(instance.address).toNumber();                
                assert(newContBalance - contractBalance >= 500, "[UT003] Invalid balance");
                done();
            });
        })        
        
    });
    /* Unit Test Case# 04:  */

});