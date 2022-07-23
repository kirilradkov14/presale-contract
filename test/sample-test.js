const { expect } = require("chai");
const { assert } = require("console");
const { ethers } = require("hardhat");

describe('Vesting Test', () => {
    function sleep(ms) {
        return new Promise((resolve) => {
            setTimeout(resolve, ms);
        });
      }
    it("Pass args, deposit tokens, reach HC, finish sale, initial claim, then wait for every period", async () =>  {
        const [creator, user1, user2, user3] = await ethers.getSigners();
        expect([creator, user1, user2, user3]).to.not.be.undefined;

        const tokenFactory = await ethers.getContractFactory("Token");
        const token = await tokenFactory.deploy();
        await token.deployed();
        console.log("Token at: " + token.address);
    
        const presaleFactory = await ethers.getContractFactory("Presale");
        const presale = await presaleFactory.deploy(creator.address, token.address, 18, '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f', true, false, 50, 25, 100);
        await presale.deployed();
        console.log('Presale at: '  + presale.address);

        const timestampNow = Math.floor(new Date().getTime()/1000);
        const initSale = await presale.connect(creator).initSale(BigInt(70000000000 * (10**18)), BigInt(50000000000*(10**18)), timestampNow + 35, timestampNow + 450, BigInt(3000000000000000), BigInt(2000000000000000), BigInt(3000000000000000), BigInt(3000000000000), 75);
        await initSale.wait();
        const approvePresale = await token.connect(creator).approve(presale.address, BigInt(1000000000000*(10**18)));
        await approvePresale.wait();
        console.log('Sale initialized');

        await sleep(50*1000);

        const makeDeposit = await presale.connect(creator).deposit();
        await makeDeposit.wait();
        await sleep(10*1000);
        expect(await token.balanceOf(presale.address)).to.equal(await presale.getTokenDeposit(), "Failed to deposit");
        console.log('Tokens deposited');

        const firstContribution = await user1.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.003')
        })
        await firstContribution.wait();
        console.log('User 1 makes deposit');

        await sleep(10*1000);

        const finishSale = await presale.connect(creator).finishSale();
        await finishSale.wait();
        console.log('Sale is concluded');

        await sleep(10*1000);

        const firstClaim = await presale.connect(user1).claimTokens();
        await firstClaim.wait();
        console.log("User 1 claims first time");

        console.log("First claim is completed, waiting for vesting period to expire");
        await sleep(100*1000);

        const secondClaim = await presale.connect(user1).claimTokens();
        await secondClaim.wait();
        console.log("User 1 claims second time");

        console.log("First claim is completed, waiting for vesting period to expire");
        await sleep(100*1000);
        
        const thirdClaim = await presale.connect(user1).claimTokens();
        await thirdClaim.wait();
        console.log("User 1 claims third time");
    })
})