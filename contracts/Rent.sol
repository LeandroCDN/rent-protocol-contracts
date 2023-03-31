// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Rent is ERC721URIStorage, Ownable{
  using Counters for Counters.Counter;
  
  enum states {Free,Ocuped,Stoped}
  struct PropertyData{
    address owner;
    address renter;
    states state;
    uint reserve; //in ether
    uint price; //in ether 
    uint8 minTimeToRent; // in months
    uint8 advancement; // in months
    uint32 maxTimeToRent; // in seconds
    uint32 startRentDate; // in block.timestamp
    uint32 pricePerSecond; // (price/ 30 days) Can be changed, if there is a specific conflict resolution route;
  }

  uint public totalRegisters;
  uint public volumeFee;
  Counters.Counter public tokenIdCounter;
  IERC20 public coin;

  mapping(uint id => PropertyData) public registerPropertyData;
  mapping(address => uint[] id) public ownersOfpropertyList;
  mapping(uint id => uint rentAmount) public amountToPayRents;
  mapping(uint id => uint lastClaim) public lastClaims;
  
  event Register(PropertyData newRegister, uint id);
  event NewRent(uint id, address renter, uint cantOfMonths);

  constructor(uint _volumeFee, IERC20 _coin) ERC721("Rent", "RENT"){
    volumeFee = _volumeFee;
    coin = _coin;
  }

  function register(PropertyData memory newProperty,string memory uri)public returns(uint){
    uint256 tokenId = tokenIdCounter.current();
    tokenIdCounter.increment();
    
    registerPropertyData[tokenId] = newProperty;
    ownersOfpropertyList[msg.sender].push(tokenId);
    _safeMint(address(msg.sender), tokenId);
    _setTokenURI(tokenId, uri);
    emit Register(newProperty, tokenId);
    return tokenId;
  }

  function newRent(uint id, uint cantOfMonths) public {
    PropertyData storage property = registerPropertyData[id];
    require(uint(property.state) == 0, "The property  must be in Free mode");
    require(
      property.minTimeToRent >= cantOfMonths  && cantOfMonths < property.maxTimeToRent, 
      "The property  must be in Free mode"
    );

    uint totalAmount = (property.reserve + cantOfMonths ) *  property.price;
    coin.transferFrom(msg.sender, address(this), totalAmount);
    property.startRentDate = uint32(block.timestamp);
    amountToPayRents[id] += property.price * cantOfMonths;
    property.state = states.Ocuped;
    emit NewRent(id, msg.sender, cantOfMonths);
  }

  function claimPayment(uint id) public {

  }

  function createTicket() public {

  }

  function resolveTicket(uint id) public {

  }

  // view functions
  function viewData(uint id) public view returns(PropertyData memory){

  }

  function calculatePayment(uint id) public view returns(uint){
    PropertyData memory property = registerPropertyData[id];
    require(uint(property.state) == 1);
    //This function mustbe calculate how be deliver to ownerOfProperty
    uint timeSinceLastClaim = (block.timestamp - lastClaims[id]);
    uint rentToPay = timeSinceLastClaim * uint(property.pricePerSecond);
   
    if (rentToPay <= 0) {
        return 0;
    }
    return rentToPay;

  }
  
}