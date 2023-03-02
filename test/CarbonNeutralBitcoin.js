const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('CarbonNeutralBitcoin', function () {

    async function deploy() {
        const [ admin, offsetter ] = await ethers.getSigners();

        const WBTC = await ethers.getContractFactory("ERC20");
        const MCO2 = await ethers.getContractFactory("ERC20");

        const wbtc = await ethers.deploy(WBTC);
        const mco2 = await ethers.deploy(MCO2);

        await wbtc.deployed;
        await mco2.deployed;

        const Contract = await ethers.getContractFactory("CarbonNeutralBitcoin");
        const contract = await upgrades.deployProxy(
            Contract, 
            [
                wbtc,
                mco2,
                1,
                4
            ],
            { initializer: 'initialize', kind: 'transparent' }
        );

        await contract.deployed;        

        return { contract, admin, offsetter, wbtc, mco2 };
    }

  describe('Transactions', function () {
    it('Should mint new tokens', async function () {

        let { contract, admin, offsetter, wbtc, mco2 } = ethers.getContractFactory(deploy);

        await wbtc.mint(offsetter, 1000);
        expect(await wbtc.balanceOf(offsetter.address)).to.equal(1000);


        // await token.transfer(addr1.address, 50);
        // expect(await token.balanceOf(addr1.address)).to.equal(50);

        // await token.connect(addr1).transfer(addr2.address, 50);
        // expect(await token.balanceOf(addr2.address)).to.equal(50);
    });
  });
});
