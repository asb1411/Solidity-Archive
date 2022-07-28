// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.7.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.7.2/security/Pausable.sol";
import "@openzeppelin/contracts@4.7.2/access/Ownable.sol";

contract MyFirstToken is ERC20, ERC20Burnable, Pausable, Ownable {
    uint MAXSUPPLY = 1000000000;
    
    constructor() ERC20("MyFirstToken", "MFT") {
        _mint(msg.sender, 100 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply()/10**decimals() < MAXSUPPLY, 'No more tokens are available');
        require((totalSupply() + amount)/10**decimals() <= MAXSUPPLY, 'Not enough tokens');
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

