pragma solidity ^0.8.0;

// Esto solo es un esqueleto para pensar las funciones
// no se debe implementar en produccion
// * La idea es que se puedan gestionar todas las funciones de todos los rents desde aqui
// * y gestionar los perfiles indexando sus acciones de todos los rents contract.

import "./Rent.sol";

contract RentFactory {
	address[] public rents;
	mapping(address => bool) public isUser;
	mapping(address => bool) public isPropietario;
	mapping(address => bool) public isEntidad;
	  
	function createUser() public {
	  isUser[msg.sender] = true;
	}
	
	function createPropietario() public {
	  isPropietario[msg.sender] = true;
	}
	
	function createEntidad() public {
	  isEntidad[msg.sender] = true;
	}
	
	function createRent(
	  uint _volumeFee,
	  IERC20 _coin,
	) public returns (address) {
	  require(isEntidad[msg.sender], "Solo las entidades pueden crear rent contracts");
	  Rent rent = new Rent(_volumeFee, _coin);
		rents.push(rent);
	  return address(rent);
	}
	
	function getRents() public view returns (address[] memory) {
	    return rents;
	}
	
	function registerRent(
	      address rentAddress,
	      uint _reserve,
	      uint _price,
	      uint _minTimeToRent,
	      uint _advancement,
	      uint _maxTimeToRent,
	      string memory _uri
	 ) public {
	      require(isPropietarioUser[msg.sender], "Only propietarioUser can call this function");
	      Rent(rentAddress).register(_reserve, _price, _minTimeToRent, _advancement, _maxTimeToRent, _uri);
	 }
	
	function newRent(
	      uint _volumeFee,
	      IERC20 _coin,
	      uint _reserve,
	      uint _price,
	      uint _minTimeToRent,
	      uint _advancement,
	      uint _maxTimeToRent,
	      string memory _uri,
	      address _propietarioUser
	  ) public {
	      require(isEntidad[msg.sender], "Only entidad can call this function");
	      Rent rent = new Rent(_volumeFee, _coin);
	      rent.setPropietarioUser(_propietarioUser);
	      rent.register(_reserve, _price, _minTimeToRent, _advancement, _maxTimeToRent, _uri);
	      rents.push(address(rent));
	  }

}