pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
// A+G = VNL
// https://github.com/kirilradkov14

import './Ownable.sol';

abstract contract Whitelist is Ownable{

    mapping(address => bool) whitelists;

    function wlAddress(address _user) external onlyOwner{
        require(whitelists[_user] == false, "Whitelist. Address is already whitelisted");
        require(_user != address(0), 'Whitelist. Address can not be 0 address.');

        whitelists[_user] = true;
    }

    function wlMultipleAddresses(address[] calldata  _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++){
            whitelists[_users[i]] = true;
        }
    }

    function removeAddress(address _user) external onlyOwner {
        require(whitelists[_user] == true, "Whitelist. Address is already whitelisted");
        require(_user != address(0), 'Whitelist. Address can not be 0 address.');

         whitelists[_user] = false;
    }

    function removeMultipleAddresses(address[] calldata  _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++){
            whitelists[_users[i]] = false;
        }
    }
}