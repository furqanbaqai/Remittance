var Remittance = artifacts.require("./Remittance.sol");

module.exports = function (deployer) {
    deployer.deploy(Remittance, {
        gas: 3000000,
        gasvalue: 1
    });
};