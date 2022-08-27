// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ITokenURI{
    function tokenURI_future(uint256 _tokenId,string memory _info) external view returns(string memory);
}