// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Rent is Ownable{
  using Counters for Counters.Counter;
  
  enum states {Free,Ocuped,Stoped}
  struct data{
    address owner;
    address renter;
    states state;
    uint reserve;
    uint price;
    uint minTimeToRent;
    uint advancement;
  }
  uint public totalRegisters;
  uint public volumeFee;
  Counters.Counter private _IdCounter;
  IERC20 public coin;

  mapping(uint id => data) public registerData;
  mapping(address => uint[] id) public ownersOfpropertiesList;

  constructor(uint _volumeFee, IERC20 _coin) {
    volumeFee = _volumeFee;
    coin = _coin;
  }

  function register()public returns(uint id){

  }

  function rent() public {

  }

  function claimPayment() public {

  }

  function createTicket() public {

  }

  function resolveTicket(uint id) public {

  }

  function viewData(uint id) public view returns(data memory){

  }
}