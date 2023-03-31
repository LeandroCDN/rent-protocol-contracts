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
    uint reserve; //in ether
    uint price; //in ether 
    uint8 minTimeToRent; // in months
    uint8 advancement; // in months
    uint32 maxTimeToRent; // in seconds
    uint32 startRentDate; // in block.timestamp
    uint32 pricePerSecond; // (price/ 30 days) Can be changed, if there is a specific conflict resolution route;
    uint32 endRentDate;
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
    // TODO : LOS FEES PA
    uint totalAmount = (property.reserve + cantOfMonths ) *  property.price;
    coin.transferFrom(msg.sender, address(this), totalAmount);
    amountToPayRents[id] += property.price * cantOfMonths;
    property.startRentDate = uint32(block.timestamp);
    property.state = states.Ocuped;
    property.renter = msg.sender;
    property.endRentDate = uint32(block.timestamp + (cantOfMonths * (30 days) ));
    emit NewRent(id, msg.sender, cantOfMonths);
  }

  function claimPayment(uint id) public {
    uint toPay = calculatePayment(id);
    require(amountToPayRents[id] >= toPay ,"Not founds in rents");
    require(registerPropertyData[id].state == states.Ocuped);
    require(coin.balanceOf(address(this)) >= toPay ,"Not founds in contract");
    amountToPayRents[id] -= toPay;
    coin.transfer(ownerOf(id), toPay);
    lastClaims[id] = block.timestamp;

    //TODO reset state if finish.

  }

  function createTicket(uint id, tickets memory _ticketData) public {
    // stop payments
    // estate solucion entre las dos partes x tiempo(24hrs)
    // entidad 
    PropertyData storage property = registerPropertyData[id];
    require( 
      msg.sender == ownerOf(id) || msg.sender == property.renter, 
      "solo las partes involucradas puede crear un tiket" 
    );
    property.state= states.Stoped;
    _ticketData.startTicketDate = uint16(block.timestamp);
    ticketdata[id] = _ticketData;

  }

  function resolveTicket(uint id, address winer, uint amount) public {
    tickets storage ticket = ticketdata[id];
    PropertyData storage property = registerPropertyData[id];
    //uint timeSinceTicket = uint16(block.timestamp) - ticket.startTicketDate;

    if(msg.sender == owner()){
      ticket.lastResult = winer;
      ticket.lastAmountResult = uint32(amount);
      require(amount >= (property.reserve + amountToPayRents[id]), "resolve amount");
      if(amount > property.reserve){
        uint newAmount = amount-property.reserve;
        property.reserve = 0;
        amountToPayRents[id] -=  newAmount;
        //todo recaulculate pricePerScond (amountToPayRents / (endRentDate-lastClaim) )
        property.pricePerSecond = uint32(amountToPayRents[id] / (uint(property.endRentDate) - lastClaims[id])); 
        coin.transfer(winer, amount);
      }else{
        property.reserve -= amount;
        coin.transfer(winer, amount);
      }
      property.state= states.Free;
    }
  }

  // view functions
  function viewData(uint id) public view returns(PropertyData memory){
    return registerPropertyData[id];
  }

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