const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('CarbonNeutralBitcoin', function () {

    async function deploy() {
        const [ admin, offsetter ] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("Token");

        const wbtc = await Token.deploy('Wrapped Bitcoin', 'WBTC');
        const mco2 = await Token.deploy('Moss Carbon Offset', 'MCO2');

        await wbtc.deployed();
        await mco2.deployed();

        const Contract = await ethers.getContractFactory("CarbonNeutralBitcoin");
        const contract = await upgrades.deployProxy(
            Contract, 
            [
                wbtc.address,
                mco2.address,
                1,
                1
            ],
            { initializer: 'initialize', kind: 'transparent' }
        );

        await contract.deployed();        

        return { contract, admin, offsetter, wbtc, mco2 };
    }

  describe('Transactions', function () {

    it('Should be blacklist allowed when blacklist disabled', async function () {
        
        let { contract, admin, offsetter, wbtc, mco2 } = await loadFixture(deploy);

        expect(await contract.connect(admin).checkBlacklistAllowed(offsetter.address, contract.address)).to.be.true;
    });

    it('Should be blacklist allowed when blacklist enabled and address not blacklisted', async function () {
        
        let { contract, admin, offsetter, wbtc, mco2 } = await loadFixture(deploy);

        await contract.setBlacklistEnabled(true);

        expect(await contract.connect(admin).checkBlacklistAllowed(offsetter.address, contract.address)).to.be.true;
    });

    it('Should be blacklist denied when address blacklisted', async function () {
        
        let { contract, admin, offsetter, wbtc, mco2 } = await loadFixture(deploy);

        await contract.setBlacklistEnabled(true);

        await contract.connect(admin).addToBlacklist(offsetter.address);

        expect(await contract.connect(admin).checkBlacklistAllowed(offsetter.address, contract.address)).to.be.false;
    });


    it('Should mint new tokens', async function () {

        let { contract, admin, offsetter, wbtc, mco2 } = await loadFixture(deploy);

        await wbtc.mint(offsetter.address, 1000);
        await mco2.mint(offsetter.address, 1000);
        
        await wbtc.connect(offsetter).approve(contract.address, wbtc.balanceOf(offsetter.address));
        await mco2.connect(offsetter).approve(contract.address, mco2.balanceOf(offsetter.address));

        await contract.mint(offsetter.address, 50);
        
        expect(await wbtc.balanceOf(offsetter.address)).to.equal(950);
        expect(await mco2.balanceOf(offsetter.address)).to.equal(950);
        expect(await contract.balanceOf(offsetter.address)).to.equal(50);

    });

    it('Should burn tokens', async function () {

        let { contract, admin, offsetter, wbtc, mco2 } = await loadFixture(deploy);

        await wbtc.mint(offsetter.address, 1000);
        await mco2.mint(offsetter.address, 1000);
        
        await wbtc.connect(offsetter).approve(contract.address, wbtc.balanceOf(offsetter.address));
        await mco2.connect(offsetter).approve(contract.address, mco2.balanceOf(offsetter.address));

        await contract.mint(offsetter.address, 50);

        await contract.connect(offsetter).burn(50);
        
        expect(await wbtc.balanceOf(offsetter.address)).to.equal(1000);
        expect(await mco2.balanceOf(offsetter.address)).to.equal(950);
        expect(await contract.balanceOf(offsetter.address)).to.equal(0);

    });    

  });
});
