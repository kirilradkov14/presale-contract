import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { 
    Presale, 
    Token, 
    WETH,
} from "../typechain-types";

function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

describe("Presale test", function(){
    let weth:WETH;
    let token:Token;
    let presale:Presale;
    let contributions = [];

    before("Deploy contracts", async function() {
        
    });

    it("Example test", async function() {
        const TOTAL_SUPPLY:bigint = 1_000_000_000n * 10n ** 18n;
        const name:string = "TestToken";
        const symbol:string = "TEST";
        const signers = await ethers.getSigners();
        const uniswapV2Router02:string = "0x000000000000000000000000000000000000dEaD";
        const timeNow = Math.floor(Date.now() / 1000);
        const pool = {
            tokenDeposit: ethers.parseUnits("1000000000", 18), // 1B tokens
            hardCap: ethers.parseUnits("700", 18),
            softCap: ethers.parseUnits("350", 18),
            max: ethers.parseUnits("3", 18),
            min: ethers.parseUnits("0.1", 18),
            start: timeNow + 25,
            end: timeNow + 170,
            liquidityBps: 5000
        };
        
        const WETH = await ethers.getContractFactory("WETH");
        weth = await WETH.deploy();
        await weth.waitForDeployment();

        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy(TOTAL_SUPPLY, name, symbol);
        await token.waitForDeployment();
        
        const Presale = await ethers.getContractFactory("Presale");
        presale = await Presale.deploy(weth.target, token.target, uniswapV2Router02, pool);
        await presale.waitForDeployment();

        const approveTokens = await token.approve(presale.target, TOTAL_SUPPLY);
        await approveTokens.wait();

        const tokenDeposit = await presale.deposit();
        await tokenDeposit.wait();
    
        await sleep(5000);

        console.log('Token balance before : ' + ethers.formatEther(await token.balanceOf(presale.target)));

        // Random contributions
        for (let i = 1; i < signers.length; i++) {
            const randomEtherAmount = Math.random() * (3 - 0.1) + 0.1; // Value between 0.1 and 3 ethers
            const purchaseValue = ethers.parseEther(randomEtherAmount.toString());
            const purchase = await signers[i].sendTransaction({
                to: presale.target,
                value: purchaseValue,
            });
            await purchase.wait();
            contributions.push({
                address: signers[i].address,
                ethContributed: randomEtherAmount.toFixed(2),
                tokensClaimed: "0.00" // Initialize as a string to ensure type consistency
            });
            console.log(`${signers[i].address} Contributd ${randomEtherAmount.toFixed(2)} ETH.`);
            
        }

        await sleep(80000);

        // Finalizing the presale
        const finalize = await presale.finalize();
        await finalize.wait();

        // Loop and claim tokens
        for (let i = 1; i < signers.length; i++) {
            const claim = await presale.connect(signers[i]).claim();
            await claim.wait();
            const tokensClaimed = await token.balanceOf(signers[i].address);
            contributions[i - 1].tokensClaimed = ethers.formatEther(tokensClaimed);
        }
        console.table(contributions);
    });

    after("Expected assertions after execution", async function() {
        console.log('Token balance  : ' + ethers.formatEther(await token.balanceOf(presale.target)));
    });
});