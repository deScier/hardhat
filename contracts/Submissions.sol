// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Submissions is IERC1155MetadataURI,ERC1155,Ownable {
    string public name;
    string public symbol;
    uint256 public price;
    string public contractURI;

    uint256 private _totalSupply = 0;
    string private _tokenURIPrefix;

    using SafeMath for uint256;
    mapping(bytes32 => bool) private uriHashUsed;
    mapping(uint256 => string) private _uris;
    mapping(bytes32 => address) public submissionAuthor;

    event Submited(address indexed from, string uri,bytes32 uriHash);

    constructor(string memory _name,
                string memory _symbol,
                string memory _contractURI,
                string memory tokenURIPrefix,
                uint256 _price) ERC1155(_contractURI) {
        name = _name;
        symbol = _symbol;
        price = _price;
        contractURI = _contractURI;
        _tokenURIPrefix = tokenURIPrefix;
    }

    function submit(string memory _uri) external payable {
      require(msg.value == price,"Wrong msg.value");
      (bool sent,) = payable(owner()).call{value: msg.value}("");
      require(sent, "Failed to send Ether");
      bytes32 uriHash = keccak256(abi.encodePacked(_uri));
      require(!uriHashUsed[uriHash],"Uri already was submited");
      uriHashUsed[uriHash] = true;
      submissionAuthor[uriHash] = msg.sender;
      emit Submited(msg.sender,_uri,uriHash);

    }

    function mint(uint256 supply,string memory _uri) external onlyOwner {
        bytes32 uriHash = keccak256(abi.encodePacked(_uri));
        address author = submissionAuthor[uriHash];
        require(uriHashUsed[uriHash],"Token with this uri was not submited");
        _totalSupply = _totalSupply.add(1);
        _uris[_totalSupply] = _uri;
        _mint(author,_totalSupply, supply, bytes(_uri));

    }


    function setprice(uint256 _price) external onlyOwner {
      price = _price;
    }

    function totalSupply() public view returns (uint256) {
      return(_totalSupply);
    }
    function uri(uint256 id) override(ERC1155,IERC1155MetadataURI) public view returns (string memory){
      return(string(abi.encodePacked(_tokenURIPrefix,_uris[id])));
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
      revert();
    }

}
