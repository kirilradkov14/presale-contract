// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILocker {
    function lockTokens(address token, uint256 amount, uint256 unlockTime) external returns(uint256);
}

contract Locker is Ownable {
    
    struct Lock {
        address tokenAddress;
        address locker;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping(address => uint256[]) public lockerDeposits;
    mapping(uint256 => Lock) public lockedToken;
    mapping(address => mapping(address => uint256)) public walletTokenBalance;

    event Withdrawal(address indexed _recipent, uint256 _amount);
    
    constructor() {

    }

    function lockTokens(
        address _tokenAddress, 
        uint256 _amount, 
        uint256 _unlockTime
        ) external returns(uint256 _id) {
            
        require(_amount > 0, 'token amount is Zero');
        require(_unlockTime < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
        require(IERC20(_tokenAddress).approve(address(this), _amount), 'Approve tokens failed');
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), 'Transfer of tokens failed');
        
        //update balance in address
        walletTokenBalance[_tokenAddress][msg.sender] = walletTokenBalance[_tokenAddress][msg.sender] + _amount;
        
        address _locker = msg.sender;
        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].locker = _locker;
        lockedToken[_id].tokenAmount = _amount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;
        
        allDepositIds.push(_id);
        lockerDeposits[_locker].push(_id);

    }

    function unlockTokens(uint256 _id) external {
        require(block.timestamp >= lockedToken[_id].unlockTime, 'Tokens are locked');
        require(msg.sender == lockedToken[_id].locker, 'Can withdraw by withdrawal Address only');
        require(!lockedToken[_id].withdrawn, 'Tokens already withdrawn');
        require(IERC20(lockedToken[_id].tokenAddress).transfer(msg.sender, lockedToken[_id].tokenAmount), 'Transfer of tokens failed');
        
        lockedToken[_id].withdrawn = true;
        
        //update balance in address
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] - lockedToken[_id].tokenAmount;
        
        //remove this id from this address
        uint256 i; 
        uint256 j;
        for(j = 0; j < lockerDeposits[lockedToken[_id].locker].length; j++){
            if(lockerDeposits[lockedToken[_id].locker][j] == _id){
                for (i = j; i<lockerDeposits[lockedToken[_id].locker].length-1; i++){
                    lockerDeposits[lockedToken[_id].locker][i] = lockerDeposits[lockedToken[_id].locker][i+1];
                }
                lockerDeposits[lockedToken[_id].locker].length - 1;
                break;
            }
        }
        emit Withdrawal(msg.sender, lockedToken[_id].tokenAmount);
    }

    /*get total token balance in contract*/
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
    {
       return IERC20(_tokenAddress).balanceOf(address(this));
    }
    
    /*get total token balance by address*/
    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256)
    {
       return walletTokenBalance[_tokenAddress][_walletAddress];
    }
    
    /*get allDepositIds*/
    function getAllDepositIds() view public returns (uint256[] memory)
    {
        return allDepositIds;
    }
    
    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id) view public returns (address, address, uint256, uint256, bool)
    {
        return(lockedToken[_id].tokenAddress,lockedToken[_id].locker,lockedToken[_id].tokenAmount,
        lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }
    
    /*get lockerDeposits*/
    function getlockerDeposits(address _locker) view public returns (uint256[] memory)
    {
        return lockerDeposits[_locker];
    }
}