// SPDX-License-Identifier: Unlicensed
// https://github.com/kirilradkov14
pragma solidity ^0.8.19;

import "./access/Ownable.sol";
import "./proxy/Clones.sol";
import "./utils/Address.sol";

abstract contract PresaleFactory is Ownable {
    using Address for address payable;
    address [] public presales;
    address private implementation;
    address private admin;
    uint8 private fee;

    struct Data {
        address weth;
        address creator;
        address tokenAddress;
        address uniswapv2Router;
        address uniswapv2Factory;
        uint256 presaleTokens;
        uint256 ethRaised;
        bool burnUnsold;
        uint8 tokenDecimals;
    }

    struct Pool {
        uint256 saleRate;
        uint256 listingRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
        uint64 startTime;
        uint64 endTime;
        uint8 status;
        uint8 liquidityPortion;
    }

    struct Arguments {
        Data data;
        Pool pool;
    }

    event PresaleCreated(address indexed _presale, address indexed _creator);
    event FeeUpdated(uint8 indexed _oldFee, uint8 indexed _newFee);
    event AdminUpdated(address indexed _oldAdmin, address indexed _newAdmin);

    constructor(
        address _implementation,
        address _admin,
        uint8 _fee
    ){
        require(_implementation != address(0), "Implementation cant be 0");
        require(_admin != address(0), "Admin cant be 0");

        implementation = _implementation;
        admin = _admin;
        fee = _fee;
    }

    function updateFee(uint8 _newFee) external onlyOwner {
        require(_newFee != fee, "Invalid fee");
        require(_newFee <= 2, "Fee value exceeds limit");

        emit FeeUpdated(fee, _newFee);

        fee = _newFee;
    }

    function updateAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != admin, "New feeTaker must be different from feeTaker");
        require(_newAdmin != address(0), "New feeTaker cant be 0 address");

        emit AdminUpdated(admin, _newAdmin);

        admin = _newAdmin;
    }

    function createPresale(Arguments calldata args) payable external returns (address presale) {
        require(msg.sender == tx.origin, "Caller is a smart contract");
        require(msg.value == fee, "Invalid fee amount");

        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        presale = Clones.cloneDeterministic(implementation, salt);

        // solhint-disable max-line-length
        (bool success, ) = presale.call{value: msg.value}(abi.encodeWithSignature(
            "initialize((address,address,address,address,uint256,uint256,bool,uint8),(uint256,uint256,uint256,uint256,uint256,uint256,uint64,uint64,uint8,uint8))",
            args.data,
            args.pool
        ));

        require(success, "Initialization failed.");

        presales.push(presale);

        emit PresaleCreated(presale, msg.sender);

        return presale;
    }
}
