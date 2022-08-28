// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import { BitOpe } from './libs/BitOpe.sol';
import "./interface/ItokenURI.sol";
import "hardhat/console.sol"; // Hardhat console log

contract SmartGenerative is ERC721A, Ownable,ERC2981 {
    using BitOpe for uint64;
    using Strings for uint256;

    enum Phase {
        BeforeMint,
        WLMint,
        BurnMint
    }

    // Upgradable FullOnChain
    ITokenURI public tokenuri;

    address public constant withdrawAddress = 0x6A1Ebf8f64aA793b4113E9D76864ea2264A5d482;
    uint256 public maxSupply = 10000;
    uint256 public maxBurnMint = 2000;
    uint256 public preLimitMint = 1;
    uint256 public cost = 0.001 ether;
    string public baseURI = "ipfs://xxx/";
    string public baseExtension = ".json";
    bytes32 public merkleRoot = 0;
    uint256 public wlcount = 1; // max:65535 Always raiseOrder!
    uint256 public bmcount = 1; // max:65535 Always raiseOrder!
    Phase public phase = Phase.BeforeMint;
    address public royaltyAddress;
    uint96 public royaltyFee = 1000;    // default:10%
  
    constructor() ERC721A('nft_name', 'nft_symbol') {
        //_safeMint(withdrawAddress, 0);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // aux->00..15:wl_count,16..31:wl_amount,32..47:burnmint_count,48..63:burnmint_amount
    function _checkWLCount(address _owner) internal {
        uint64 _auxval = _getAux(_owner);
        if(_auxval.get16_forAux(0) < wlcount){
            _auxval = _auxval.set16_forAux(0,uint64(wlcount));
            _auxval = _auxval.set16_forAux(1,0);    // Clear
            _setAux(_owner,_auxval);
        }
    }
    function _checkMBCount(address _owner) internal {
        uint64 _auxval = _getAux(_owner);
        if(_auxval.get16_forAux(2) < bmcount){
            _auxval = _auxval.set16_forAux(2,uint64(bmcount));
            _auxval = _auxval.set16_forAux(3,0);    // Clear
            _setAux(_owner,_auxval);
        }
    }
    function _getAuxforWLCount(address _owner) internal returns (uint64) {
        _checkWLCount(_owner);
        uint64 _auxval = _getAux(_owner);
        return _auxval.get16_forAux(0);
    }
    function _getAuxforWLAmount(address _owner) internal returns (uint64) {
        _checkWLCount(_owner);
        uint64 _auxval = _getAux(_owner);
        return _auxval.get16_forAux(1);
    }
    function _getAuxforBMCount(address _owner) internal returns (uint64) {
        _checkMBCount(_owner);
        uint64 _auxval = _getAux(_owner);
        return _auxval.get16_forAux(2);
    }
    function _getAuxforBMAmount(address _owner) internal returns (uint64) {
        _checkMBCount(_owner);
        uint64 _auxval = _getAux(_owner);
        return _auxval.get16_forAux(3);
    }

    function _setAuxforWL(address _owner, uint64 _aux) internal{
        _checkWLCount(_owner);
        uint64 _auxval = _getAux(_owner);
        _setAux(_owner,_auxval.set16_forAux(1,_aux));
    }

    function _setWLmintedCount(address _owner,uint256 _mintAmount) internal{
        uint64 _auxval = _getAuxforWLAmount(_owner);
        unchecked {
            _auxval += uint64(_mintAmount);
        }
        //require(_auxval < 256,"minted count is over");
        _setAuxforWL(_owner,_auxval);
    }

    function _setAuxforBM(address _owner, uint64 _aux) internal{
        _checkWLCount(_owner);
        uint64 _auxval = _getAux(_owner);
        _setAux(_owner,_auxval.set16_forAux(3,_aux));
    }

    function _setBMmintedCount(address _owner,uint256 _mintAmount) internal{
        uint64 _auxval = _getAuxforBMAmount(_owner);
        unchecked {
            _auxval += uint64(_mintAmount);
        }
        //require(_auxval < 256,"minted count is over");
        _setAuxforBM(_owner,_auxval);
    }

    // public---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        if(address(tokenuri) == address(0))
        {
            return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
        }else{
            return tokenuri.tokenURI_future(tokenId,string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension)));
        }
        
    }

    function getWLRemain(address _value,uint256 _wlAmountMax,bytes32[] calldata _merkleProof
    ) public returns (uint256) {
        uint256 _Amount = 0;
        if(phase == Phase.WLMint){
            if(getWLExit(_value,_wlAmountMax,_merkleProof) == true){
                if(preLimitMint<_wlAmountMax){
                    _Amount = preLimitMint - _getAuxforWLAmount(_value);
                }else{
                    _Amount = _wlAmountMax - _getAuxforWLAmount(_value);
                }
            } 
        }
        return _Amount;
    }

    function getBMRemain(address _value,uint256 _wlAmountMax,bytes32[] calldata _merkleProof
    ) public returns (uint256) {
        uint256 _Amount = 0;
        if(phase == Phase.BurnMint){
            if(getWLExit(_value,_wlAmountMax,_merkleProof) == true){
                if(preLimitMint<_wlAmountMax){
                    _Amount = preLimitMint - _getAuxforBMAmount(_value);
                }else{
                    _Amount = _wlAmountMax - _getAuxforBMAmount(_value);
                }
            } 
        }
        return _Amount;
    }

    function getWLExit(address _value,uint256 _wlAmountMax,bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bool _exit = false;
        bytes32 _leaf = keccak256(abi.encodePacked(_value,_wlAmountMax));   

        //console.log("_value %s _wlAmountMax %s", _value, _wlAmountMax);
        //console.logBytes32(_leaf);

        if(MerkleProof.verify(_merkleProof, merkleRoot, _leaf) == true){
            _exit = true;
        }
        return _exit;
    }

    function getTotalBurned() public view returns (uint256) {
        return _totalBurned();
    }
   
    // mint
    function mint_onlywl(uint256 _mintAmount,uint256 _wlAmountMax,bytes32[] calldata _merkleProof)public payable {
        require(phase == Phase.WLMint,"sale is not active");
        require(tx.origin == msg.sender,"the caller is another controler");
        require(getWLExit(msg.sender,_wlAmountMax,_merkleProof),"You don't have a whitelist!");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= getWLRemain(msg.sender,_wlAmountMax,_merkleProof), "claim is over max amount");
        require(_mintAmount + totalSupply() <= maxSupply, "claim is over the max supply");
        require(msg.value >= cost * _mintAmount, "not enough eth");
    
        _setWLmintedCount(msg.sender, _mintAmount);
        _safeMint(msg.sender, _mintAmount);
    }

    function  burnMint(uint256[] memory _burnTokenIds,uint256 _wlAmountMax,bytes32[] calldata _merkleProof) external payable{
        require(phase == Phase.BurnMint,"sale is not active");
        require(tx.origin == msg.sender,"the caller is another controler");
        require(getWLExit(msg.sender,_wlAmountMax,_merkleProof),"You don't have a whitelist!");
        require(_burnTokenIds.length > 0, "need to mint at least 1 NFT");
        require(_burnTokenIds.length <= getBMRemain(msg.sender,_wlAmountMax,_merkleProof), "claim is over max amount");
        require(_burnTokenIds.length + _totalBurned() <= maxBurnMint, "over total burn count");
        require(msg.value >= cost * _burnTokenIds.length, "not enough eth");
        
        _setBMmintedCount(msg.sender,_burnTokenIds.length);
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require (msg.sender == ownerOf(tokenId));
            _burn(tokenId);
        }
        _safeMint(msg.sender, _burnTokenIds.length);
    }
  
    // onlyOwner
    function setMaxSupply(uint256 _value) public onlyOwner {
        maxSupply = _value;
    }

    function setMaxBurnMint(uint256 _value) public onlyOwner {
        maxBurnMint = _value;
    }

    function setCost(uint256 _value) public onlyOwner {
        cost = _value;
    }
  
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        require( _newPhase <= Phase.BurnMint,"no Valid");
        phase = _newPhase;
    }

    function setWlcount() public onlyOwner {
        require( wlcount < 65535,"no Valid");
        wlcount += 1;
    }

    function setBMcount() public onlyOwner {
        require( bmcount < 65535,"no Valid");
        bmcount += 1;
    }
 
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    //set Default Royalty._feeNumerator 500 = 5% Royalty
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    //Change the royalty address where royalty payouts are sent
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }
}
