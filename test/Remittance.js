/**
 * Unit Test Case for testing Remittance contract
 */
Promise = require("bluebird");
Promise.promisifyAll(web3.eth, {
    suffix: "Promise"
});

var Remittance = artifacts.require("./Remittance.sol");
var remittanceCont;

contract('Remittance', function (accounts) {
    var carolAccount = accounts[0]; // Carol is the owner of the exchange house;
    var aliceAccount = accounts[1];
    var bobAccount = accounts[2];
    var contractBalance;
    beforeEach(function (/* done*/) {
        return remittanceCont = Remittance.new({
            from: carolAccount,
            gas: 3000000,
            gasvalue: 1
        });
        /*done();*/
    });
    /* Unit Test Case# 01: Check if contract was instanciated */
    it("[UT01] Check if the instance exist", function (/*done*/) {
        assert(typeof (remittanceCont), "object", "[UT001] Failure: Invalid object");        
    });
    /* Unit test Case# 02: Check if the owner is carol / account[0] */
    it("[UT02] Owner should be Carol", function (/*done*/) {
        // Assumption: alice have enough money
        return remittanceCont.then(instance => {
            return instance.owner.call();
        }).then(owner => {
            assert(owner == carolAccount, "[UT02] Invalid Owner ID " + owner);            
            /*done();*/
        });/*.catch(done);*/
    });
    /* Unit Test Case# 03: Send remittance transaction of 50wei from alice to bob */
    it("[UT03] Send Remittance transaction of 50wei from alice to bob", function (/*done*/) {
        let instance;
        var otp1 = web3.fromAscii("7745");
        var otp2 = web3.fromAscii("8291");
        var payID = web3.fromAscii("00001");

        return remittanceCont.then(_instance => {
            // Get alice and bob's balances
            instance = _instance;            
            return web3.eth.getBalancePromise(instance.address)
        }).then(_contractBalance => {
            contractBalance = _contractBalance;
            return instance.hashHelper.call(bobAccount, otp1, otp2, payID);
        }).then(puzzle => {
            return instance.sendRemitance(puzzle, bobAccount, { from: aliceAccount, value: 400 })
        }).then(txHash => {
            return web3.eth.getBalancePromise(instance.address)
        }).then(newContBalance => {            
            assert(newContBalance.minus(contractBalance).toString(10) >= 500, "[UT003] Invalid balance");
           /* done(); */           
        })/*.catch(done)*/;

    });

});