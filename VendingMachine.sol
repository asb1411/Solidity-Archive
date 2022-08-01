// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "@openzeppelin/contracts@4.7.2/access/Ownable.sol";


//  ==========  VendingMachine Contract    ==========

contract VendingMachine is Ownable{

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    // Total Items available in the machine
    uint totalItems;

    // Mapping of itemId to supply of that item
    mapping (uint => uint) totalSupplyOf;

    // Mapping of itemId to price of that item
    mapping (uint => uint) priceOf;

    // Mapping of buyer address to (itemId, supply) bought
    mapping (address => mapping (uint => uint)) buyers;


    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when Machine starts for the first time
    event VendingMachineStarted();

    /// @dev emitted when new item is added to the machine
    event NewItemAdded(uint _itemId, uint _supply, uint _price);

    /// @dev emitted when price of a item is modified
    event PriceUpdated(uint _itemId, uint _price);

    /// @dev emitted when an item is bought by a buyer
    event ItemBought(uint _itemId, uint _supply, uint _price);

    /// @dev emitted when funds withdrawn by the owner
    event Withdraw(uint _balance);


    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        emit VendingMachineStarted();
    }


    /*///////////////////////////////////////////////////////////////
                            Getter Functions
    //////////////////////////////////////////////////////////////*/

    function getTotalItems() public view returns(uint) {
        return totalItems;
    }

    function getBalance(uint _item) public view returns(uint) {
        return buyers[msg.sender][_item];
    }

    function getSupplyOf(uint _item) public view returns(uint) {
        return totalSupplyOf[_item];
    }

    function getPriceOf(uint _item) public view returns(uint) {
        require(isItemAvailable(_item), 'Item not yet added with this ID');
        return priceOf[_item];
    }

    function isItemAvailable(uint _itemId) public view returns(bool) {
        return !(totalSupplyOf[_itemId] == 0);
    }


    /*///////////////////////////////////////////////////////////////
                            State Changing Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Item price can be modifies, do not use for adding new items
    function setItemPrice(uint _itemId, uint _price) public onlyOwner {
        priceOf[_itemId] = _price;
        emit PriceUpdated(_itemId, _price);
    }

    /// @dev Add new items, do not use for changing price
    function addItem(uint _itemId, uint _supply, uint _price) public onlyOwner {
        totalSupplyOf[_itemId] = _supply;
        priceOf[_itemId] = _price;
        totalItems++;
        emit NewItemAdded(_itemId, _supply, _price);
    }

    function buyItem(uint _itemId, uint _supply) public payable {
        require(totalSupplyOf[_itemId] >= _supply, 'Quantity not available');
        uint price = getPriceOf(_itemId);
        require(price*_supply == msg.value, 'Value sent not enough to buy supplies');

        totalSupplyOf[_itemId]-=_supply;

        if(totalSupplyOf[_itemId] == 0) {
            delete totalSupplyOf[_itemId];
            totalItems -= 1;
        }

        buyers[msg.sender][_itemId] += _supply;
        emit ItemBought(_itemId, _supply, price);
    }

    function withdraw() public onlyOwner {
        uint _balance = address(this).balance;
        require(address(this).balance > 0);
        (bool sent, ) = owner().call{value: _balance}("");
        require(sent, "Failed to send Ether");
        emit Withdraw(_balance);
    }
}
