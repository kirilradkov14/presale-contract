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
        const WETH = await ethers.getContractFactory("WETH");
        weth = await WETH.deploy();
        await weth.waitForDeployment();

        // Deploy mock ERC20 token
        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy(TOTAL_SUPPLY);
        await token.waitForDeployment();
        
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
        presale = await Presale.deploy(weth.target, "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008", "0x7E0987E5b3a30e3f2828572Bb659A548460a3003");
        await presale.waitForDeployment();
        console.log(presale.target);
        
    });

    it("Execution", async function(){

    });

    after("Expected assertions after exectution", function(){

    });

});