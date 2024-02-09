import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { Address, Presale, Token, WETH, } from "../typechain-types";

describe("Expected presale behaviour", function(){
    const DEAD:Address|string = "0x000000000000000000000000000000000000dEaD";
    const TOTAL_SUPPLY:bigint = 69_696_969n * 10n ** 18n;
    // let signers:HardhatEthersSigner[];

    let signers:any;
    let weth:WETH;
    let token:Token;
    let presale:Presale;
    let uniswapV2Factory:any;
    let uniswapV2Router:any;

    before("Set environment", async function(){
        signers = await ethers.getSigners();
        
        // Deploy a mock WETH9
        // const WETH = await ethers.getContractFactory("WETH");
        // weth = await WETH.deploy();
        // await weth.waitForDeployment();

        // Deploy mock ERC20 token
        // const Token = await ethers.getContractFactory("Token");
        // token = await Token.deploy(TOTAL_SUPPLY);
        // await token.waitForDeployment();
        
        // // Deploy mock uniswapV2Factory
        // const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
        // uniswapV2Factory = await UniswapV2Factory.deploy(signers[0].address);
        // await uniswapV2Factory.waitForDeployment();
        
        // // Deploy mock uniswapV2Router
        // const UniswapV2Router = await ethers.getContractFactory("UniswapV2Router02");
        // uniswapV2Router = await UniswapV2Router.deploy(uniswapV2Factory.target, weth.target);
        // await uniswapV2Router.waitForDeployment();

        // Deploy Presale      
        const Presale = await ethers.getContractFactory("Presale");
        presale = await Presale
        .deploy("0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9", "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008", "0x7E0987E5b3a30e3f2828572Bb659A548460a3003");
        await presale.waitForDeployment();
        console.log(presale.target);
        
    });

    it("Execution", async function(){
        // signers = await ethers.getSigners();
        const timeNow = Math.floor(Date.now() / 1000);

        const saleArgs:any = {
            token: "0xE0d7C7C2940ddF078C09D5A5eF2b38e530E023Fa",
            saleRate: ethers.parseEther("10"), //10 tokens per 1 wei
            listingRate:ethers.parseEther("5"), // 5 tokens per 1 wei
            hardCap: ethers.parseEther("0.01"),
            softCap: ethers.parseEther("0.005"),
            max: ethers.parseEther("0.005"),
            min: ethers.parseEther("0.001"),
            start: timeNow - 300,
            end: timeNow + 650,
            liquidity: 60,
            refundOptions: 0
        }
        // create presale 
        const create = await presale.connect(signers[0]).createPresale(saleArgs);
        await create.wait();
        console.log();
        
        // console.log(presale.data.arguments[5]);
        
        // expect(presale.data.arguments[5]);

    });

    after("Expected assertions after exectution", function(){

    });

});