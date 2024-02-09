import { ethers, run } from "hardhat";
async function main() {
    const TOTAL_SUPPLY:bigint = 69_696_969n * 10n ** 18n;
    // const address = process.argv[2];

    // await run("verify:verify", {
    //     address: "0xA75c2cF6449c02318ab51f25C0201F42c10623e0",
    //     constructorArguments: [
    //         TOTAL_SUPPLY
    //     ],
    // });    

    await run("verify:verify", {
        address: "0x93495e0e96925b287174756C1F7E960dd0234C33",
        constructorArguments: [
            "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9", 
            "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008", 
            "0x7E0987E5b3a30e3f2828572Bb659A548460a3003"
        ],
    });    
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  