// const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
// const { expect } = require('chai');
// const { ethers, upgrades } = require('hardhat');

// describe("Blacklistable", function () {

//     async function deploy() {
//         const [ admin, blacklisted, whitelisted ] = await ethers.getSigners();
//         const Contract = await ethers.getContractFactory("Blacklistable");
//         const contract = await upgrades.deployProxy(
//             Contract, { initializer: false, kind: 'transparent' }
//         );

//         await contract.deployed;

//         return { contract, admin, blacklisted, whitelisted };
//     }

//     describe("Deployment", function () {
//         it("Should add to blacklist", async () => {
//             const { contract, admin, blacklister, blacklisted } = await loadFixture(deploy);

//             await contract.connect(admin.address).addToBlacklist(blacklisted.address);
//             expect(contract.checkBlacklistAllowed(blacklister, blacklisted)).to.be(true);
//         });
//     });
// });