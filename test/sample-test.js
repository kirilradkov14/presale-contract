const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('Sample Test', () => { 
    function sleep(ms) {
        return new Promise((resolve) => {
            setTimeout(resolve, ms);
        });
      }
    it.skip("Pass args, deposit tokens, reach HC, finish sale, claim", async () =>  {
        const [creator, user1, user2, user3] = await ethers.getSigners();
        expect([creator, user1, user2, user3]).to.not.be.undefined;

        const tokenFactory = await ethers.getContractFactory("Token");
        const token = await tokenFactory.deploy();
        await token.deployed();
        console.log("Token at: " + token.address);
    
        const presaleFactory = await ethers.getContractFactory("Presale");
        const presale = await presaleFactory.deploy(creator.address, token.address, 18, '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f', 2, '0xced1cB80C96D4b98DbcBbD20af69A5396Ec3507C', '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6', false);
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
            value: ethers.utils.parseEther('0.001')
        })
        await firstContribution.wait();
        console.log('User 1 makes deposit');
      
        const secondContribution = await user2.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.001')
        })
        await secondContribution.wait();
        console.log('User 2 makes deposit');

        const thirdContribution = await user3.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.001')
        })
        await thirdContribution.wait();
        console.log('User 3 makes deposit');

        const finishSale = await presale.connect(creator).finishSale();
        await finishSale.wait();
        console.log('Sale is concluded');
    
        const firstClaim = await presale.connect(user1).claimTokens();
        await firstClaim.wait();
        console.log("User 1 claims");

        const secondClaim = await presale.connect(user2).claimTokens();
        await secondClaim.wait();
        console.log("User 2 claims");
    
        const thirdClaim = await presale.connect(user3).claimTokens();
        await thirdClaim.wait();
        console.log("User 3 claims");
    });

    it.skip("Pass args, deposit tokens, reach SC, wait for the time to expire, finish sale, claim", async()=>{
        const [creator, user1, user2, user3] = await ethers.getSigners();
        expect([creator, user1, user2, user3]).to.not.be.undefined;

        const tokenFactory = await ethers.getContractFactory("Token");
        const token = await tokenFactory.deploy();
        await token.deployed();
        console.log("Token at: " + token.address);
    
        const presaleFactory = await ethers.getContractFactory("Presale");
        const presale = await presaleFactory.deploy(creator.address, token.address, 18, '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f', 4, '0xced1cB80C96D4b98DbcBbD20af69A5396Ec3507C', '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6', true);
        await presale.deployed();
        console.log('Presale at: '  + presale.address);

        
        const timestampNow = Math.floor(new Date().getTime()/1000);
        const initSale = await presale.connect(creator).initSale(BigInt(70000000000 * (10**18)), BigInt(50000000000*(10**18)), timestampNow + 35, timestampNow + 450, BigInt(6000000000000000), BigInt(4000000000000000), BigInt(3000000000000000), BigInt(3000000000000), 75);
        await initSale.wait();
        const approvePresale = await token.connect(creator).approve(presale.address, BigInt(1000000000000*(10**18)));
        await approvePresale.wait();
        console.log('Sale initialized');

        await sleep(30*1000);

        const makeDeposit = await presale.connect(creator).deposit();
        await makeDeposit.wait();
        await sleep(10*1000);
        expect(await token.balanceOf(presale.address)).to.equal(await presale.getTokenDeposit(), "Failed to deposit");
        console.log('Tokens deposited');

        const firstContribution = await user1.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.002')
        })
        await firstContribution.wait();
        console.log('User 1 makes deposit');
      
        const secondContribution = await user2.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.0015')
        })
        await secondContribution.wait();
        console.log('User 2 makes deposit');

        const thirdContribution = await user3.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.0016')
        })
        await thirdContribution.wait();
        console.log('User 3 makes deposit');

        console.log('Waiting for the sale time to finish');
        await sleep(450*1000);

        const finishSale = await presale.connect(creator).finishSale();
        await finishSale.wait();
        console.log('Sale is concluded');
    
        const firstClaim = await presale.connect(user1).claimTokens();
        await firstClaim.wait();
        console.log("User 1 claims");

        const secondClaim = await presale.connect(user2).claimTokens();
        await secondClaim.wait();
        console.log("User 2 claims");
    
        const thirdClaim = await presale.connect(user3).claimTokens();
        await thirdClaim.wait();
        console.log("User 3 claims");
    });

    it.skip("Pass args, deposit tokens, cancel sale, start refund", async() => {
        const [creator, user1, user2, user3] = await ethers.getSigners();
        expect([creator, user1, user2, user3]).to.not.be.undefined;

        const tokenFactory = await ethers.getContractFactory("Token");
        const token = await tokenFactory.deploy();
        await token.deployed();
        console.log("Token at: " + token.address);
    
        const presaleFactory = await ethers.getContractFactory("Presale");
        const presale = await presaleFactory.deploy(creator.address, token.address, 18, '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f', 2, '0xced1cB80C96D4b98DbcBbD20af69A5396Ec3507C', '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6', false);
        await presale.deployed();
        console.log('Presale at: '  + presale.address);

        
        const timestampNow = Math.floor(new Date().getTime()/1000);
        const initSale = await presale.connect(creator).initSale(BigInt(70000000000 * (10**18)), BigInt(50000000000*(10**18)), timestampNow + 35, timestampNow + 450, BigInt(6000000000000000), BigInt(4000000000000000), BigInt(3000000000000000), BigInt(3000000000000), 75);
        await initSale.wait();
        const approvePresale = await token.connect(creator).approve(presale.address, BigInt(1000000000000*(10**18)));
        await approvePresale.wait();
        console.log('Sale initialized');

        await sleep(30*1000);

        const makeDeposit = await presale.connect(creator).deposit();
        await makeDeposit.wait();
        await sleep(10*1000);
        expect(await token.balanceOf(presale.address)).to.equal(await presale.getTokenDeposit(), "Failed to deposit");
        console.log('Tokens deposited');

        const firstContribution = await user1.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.002')
        })
        await firstContribution.wait();
        console.log('User 1 makes deposit');
      
        const secondContribution = await user2.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.002')
        })
        await secondContribution.wait();
        console.log('User 2 makes deposit');

        const thirdContribution = await user3.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.002')
        })
        await thirdContribution.wait();
        console.log('User 3 makes deposit');

        const cancelSale = await presale.connect(creator).cancelSale();
        await cancelSale.wait();
        console.log("Sale canceled by creator");

        const firstRefund = await presale.connect(user1).refund();
        await firstRefund.wait();
        console.log("User 1 refunded his contribution");

        const secondRefund = await presale.connect(user2).refund();
        await secondRefund.wait();
        console.log("User 2 refunded his contribution");

        const thirdRefund = await presale.connect(user3).refund();
        await thirdRefund.wait();
        console.log("User 3 refunded his contribution");
    });

    it("pass args, deposit tokens, fail to reach SC, wait to finish, refund", async() => {
        const [creator, user1, user2, user3] = await ethers.getSigners();
        expect([creator, user1, user2, user3]).to.not.be.undefined;

        const tokenFactory = await ethers.getContractFactory("Token");
        const token = await tokenFactory.deploy();
        await token.deployed();
        console.log("Token at: " + token.address);
    
        const presaleFactory = await ethers.getContractFactory("Presale");
        const presale = await presaleFactory.deploy(creator.address, token.address, 18, '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f', 2, '0xced1cB80C96D4b98DbcBbD20af69A5396Ec3507C', '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6', false);
        await presale.deployed();
        console.log('Presale at: '  + presale.address);

        
        const timestampNow = Math.floor(new Date().getTime()/1000);
        const initSale = await presale.connect(creator).initSale(BigInt(70000000000 * (10**18)), BigInt(50000000000*(10**18)), timestampNow + 35, timestampNow + 450, BigInt(6000000000000000), BigInt(4000000000000000), BigInt(3000000000000000), BigInt(3000000000000), 75);
        await initSale.wait();
        const approvePresale = await token.connect(creator).approve(presale.address, BigInt(1000000000000*(10**18)));
        await approvePresale.wait();
        console.log('Sale initialized');

        await sleep(30*1000);

        const makeDeposit = await presale.connect(creator).deposit();
        await makeDeposit.wait();
        await sleep(10*1000);
        expect(await token.balanceOf(presale.address)).to.equal(await presale.getTokenDeposit(), "Failed to deposit");
        console.log('Tokens deposited');

        const firstContribution = await user1.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.0012')
        })
        await firstContribution.wait();
        console.log('User 1 makes deposit');
      
        const secondContribution = await user2.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.0015')
        })
        await secondContribution.wait();
        console.log('User 2 makes deposit');

        const thirdContribution = await user3.sendTransaction({
            to: presale.address,
            value: ethers.utils.parseEther('0.0015')
        })
        await thirdContribution.wait();
        console.log('User 3 makes deposit');

        console.log('Waiting for the sale time to finish');
        await sleep(450*1000)

        const firstRefund = await presale.connect(user1).refund();
        await firstRefund.wait();
        console.log("User 1 refunded his contribution");

        const secondRefund = await presale.connect(user2).refund();
        await secondRefund.wait();
        console.log("User 2 refunded his contribution");

        const thirdRefund = await presale.connect(user3).refund();
        await thirdRefund.wait();
        console.log("User 3 refunded his contribution");

        await sleep(10*1000);

        const tokenWithraw = await presale.connect(creator).withrawTokens();
        await tokenWithraw.wait();
        console.log("Sale creator withraws the deposited tokens");
    })
 })