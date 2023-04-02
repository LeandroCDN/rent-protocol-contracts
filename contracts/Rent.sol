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
    address renter;
    states state;
    uint8 minTimeToRent; // in months
    uint8 advancement; // in months
    uint32 maxTimeToRent; // in seconds
    uint32 startRentDate; // in block.timestamp
    uint32 endRentDate;
    uint reserve; //in ether
    uint price; //in ether 
    uint pricePerSecond; // (price/ 30 days) Can be changed, if there is a specific conflict resolution route;
  }

  struct tickets{
    address from;
    uint16 startTicketDate;
    string tikectUri;
    address lastResult;
    uint32 lastAmountResult;
  }

  uint public totalRegisters;
  uint public volumeFee;
  Counters.Counter public tokenIdCounter;
  IERC20 public coin;

  mapping(uint id => PropertyData) public registerPropertyData;
  mapping(address => uint[] id) public ownersOfpropertyList;
  mapping(uint id => uint rentAmount) public amountToPayRents;
  mapping(uint id => uint lastClaim) public lastClaims;
  mapping(uint id => tickets)public ticketdata;
  
  event Register(PropertyData newRegister, uint id);
  event NewRent(uint id, address renter, uint cantOfMonths);

  constructor(uint _volumeFee, IERC20 _coin) ERC721("Rent", "RENT"){
    volumeFee = _volumeFee;
    coin = _coin;
  }

  function register(
    uint reserve,
    uint price,
    uint minTimeToRent,
    uint advancement,
    uint maxTimeToRent,
    string memory uri
  )public returns(uint){
    uint256 tokenId = tokenIdCounter.current();
    tokenIdCounter.increment();
    PropertyData memory newProperty = PropertyData(
      address(0),
      states.Free,
      uint8(minTimeToRent), 
      uint8(advancement), 
      uint32(maxTimeToRent), 
      uint32(block.timestamp), 
      0,
      reserve, 
      price, 
      (price/(30 days))
    );
    
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
      property.minTimeToRent <= cantOfMonths  && cantOfMonths < property.maxTimeToRent, 
      "newRent error"
    );
    // TODO : LOS FEES PA
    uint totalAmount = property.reserve + (cantOfMonths *  property.price);
    coin.transferFrom(msg.sender, address(this), totalAmount);
    amountToPayRents[id] += property.price * cantOfMonths;
    lastClaims[id] = block.timestamp; 
    property.startRentDate = uint32(block.timestamp);
    property.state = states.Ocuped;
    property.renter = msg.sender;
    property.endRentDate = uint32(block.timestamp + (cantOfMonths * (30 days) ));
    emit NewRent(id, msg.sender, cantOfMonths);
  }


  
  function claimPayment(uint id) public {
    PropertyData storage property = registerPropertyData[id];
    uint toPay = calculatePayment(id);
    require(amountToPayRents[id] >= toPay ,"Not founds in rents");
    require(registerPropertyData[id].state == states.Ocuped);
    require(coin.balanceOf(address(this)) >= toPay ,"Not founds in contract");
    amountToPayRents[id] -= toPay;
    coin.transfer(ownerOf(id), toPay);
    lastClaims[id] = block.timestamp;
    if(property.endRentDate < block.timestamp){
      property.state = states.Free;
      property.renter = address(0);
    }
  }

  function createTicket(uint id, string memory  _ticketUri) public {
    PropertyData storage property = registerPropertyData[id];
    require(property.state == states.Ocuped, "must be occuped");
    require( 
      msg.sender == ownerOf(id) || msg.sender == property.renter, 
      "solo las partes involucradas puede crear un tiket" 
    );
    property.state= states.Stoped;
    tickets memory ticket = tickets(
      msg.sender,
      uint16(block.timestamp),
      _ticketUri,ticketdata[id].lastResult,
      ticketdata[id].lastAmountResult
    );
    ticket.startTicketDate = uint16(block.timestamp);
    ticketdata[id] = ticket;

  }

  function resolveTicket(uint id, address winer, uint amount) public {
    tickets storage ticket = ticketdata[id];
    PropertyData storage property = registerPropertyData[id];
    //uint timeSinceTicket = uint16(block.timestamp) - ticket.startTicketDate;

    if(msg.sender == owner()){
      ticket.lastResult = winer;
      ticket.lastAmountResult = uint32(amount);
      require(amount <= (property.reserve + amountToPayRents[id]), "resolve amount");
      if(amount > property.reserve){
        uint newAmount = amount-property.reserve;
        property.reserve = 0;
        amountToPayRents[id] -=  newAmount;
        property.pricePerSecond = uint(amountToPayRents[id] / (uint(property.endRentDate) - lastClaims[id])); 
        coin.transfer(winer, amount);
      }else{
        property.reserve -= amount;
        coin.transfer(winer, amount);
      }
      property.state= states.Ocuped;
    }
  }

  // view functions
  function viewData(uint id) public view returns(PropertyData memory){
    return registerPropertyData[id];
  }

  //todo fix this jock
  function calculatePayment(uint id) public view returns(uint){
    PropertyData memory property = registerPropertyData[id];
    require(uint(property.state) == 1);
    //This function mustbe calculate how be deliver to ownerOfProperty
    //TODO if the property no esta alquilada
    uint timeSinceLastClaim = (block.timestamp - lastClaims[id]);
    uint rentToPay = timeSinceLastClaim * uint(property.pricePerSecond);
   
    if (rentToPay <= 0) {
        return 0;
    }
    return rentToPay;

  }
  
}