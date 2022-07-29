// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.2/access/Ownable.sol";

contract VendingMachine is Ownable{
    uint totalItems;
    mapping (uint => uint) totalSupplyOf;
    mapping (uint => uint) priceOf;
    mapping (address => mapping (uint => uint)) buyers;

    event VendingMachineStarted();
    event NewItemAdded(uint _itemId, uint _supply, uint _price);
    event PriceUpdated(uint _itemId, uint _price);
    event ItemBought(uint _itemId, uint _supply, uint _price);

    constructor() {
        emit VendingMachineStarted();
    }

    function getTotalItems() public view returns(uint) {
        return totalItems;
    }

    function getSupplyOf(uint _item) public view returns(uint) {
        return totalSupplyOf[_item];
    }

    function getPriceOf(uint _item) public view returns(uint) {
        require(isItemAvailable(_item), 'Item not yet added with this ID');
        return priceOf[_item];
    }

    function addItem(uint _itemId, uint _supply, uint _price) public onlyOwner {
        totalSupplyOf[_itemId] = _supply;
        priceOf[_itemId] = _price;
        totalItems++;
        emit NewItemAdded(_itemId, _supply, _price);
    }

    function setItemPrice(uint _itemId, uint _price) public onlyOwner {
        priceOf[_itemId] = _price;
        emit PriceUpdated(_itemId, _price);
    }

    function isItemAvailable(uint _itemId) public view returns(bool) {
        return !(totalSupplyOf[_itemId] == 0);
    }

    function getBalance(uint _item) public view returns(uint) {
        return buyers[msg.sender][_item];
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
}
