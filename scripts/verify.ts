import { ethers, run } from "hardhat";
async function main() {
    const TOTAL_SUPPLY:bigint = 69_696_969n * 10n ** 18n;
    // const address = process.argv[2];

    await run("verify:verify", {
        address: "0xA75c2cF6449c02318ab51f25C0201F42c10623e0",
        constructorArguments: [
            TOTAL_SUPPLY
        ],
    });    
    // await run("verify:verify", {
    //     address: "0xdA96995D9F517757278FF53aC4444b340586C449",
    //     constructorArguments: [
    //         "0x641F881bcdd728e602B070E8c2Bd63d06b4c99C3",
    //         "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008",
    //         "0x7E0987E5b3a30e3f2828572Bb659A548460a3003"
    //     ],
    // });    
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  