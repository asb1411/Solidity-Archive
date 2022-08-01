// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//  ==========  Vault Contract    ==========

contract Vault {

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    // Address of the owner
    address owner;

    // Minimum locked amount necessary for deposit
    uint public MIN_LOCK_AMOUNT = 0.1 ether;

    // Minimum locked duration necessary for deposit
    uint public MIN_LOCK_DURATION = 10 seconds;

    // Mapping of sender address to amount locked
    mapping(address => uint) senderToAmount;

    // Mapping of sender to end of the duration at which the funds will be released
    mapping(address => uint) senderToDuration;


    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when Vault starts for the first time
    event VaultStarted();

    /// @dev emitted when a sender locks amount
    event AmountLocked(address indexed _sender, uint indexed _amount);

    /// @dev emitted when a sender withdraws locked amount
    event AmountWithdrawn(address indexed _sender, uint indexed _amount);

    /// @dev emitted when the owner changes the min locked amount required
    event MinLockAmountModified(uint _newLockAmount);

    /// @dev emitted when the owner changes the min duration value required
    event MinLockDurationModified(uint _newLockDuration);


    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        emit VaultStarted();
    }


    /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }


    /*///////////////////////////////////////////////////////////////
                            Getter Functions
    //////////////////////////////////////////////////////////////*/

    function getMinLockAmountRequired() public view returns(uint) {
        return MIN_LOCK_AMOUNT;
    }

    function getMinLockDurationRequired() public view returns(uint) {
        return MIN_LOCK_DURATION;
    }

    function getLockedAmount() public view returns(uint) {
        return senderToAmount[msg.sender];
    }

    function getLockedDuration() public view returns(uint) {
        return senderToDuration[msg.sender];
    }


    /*///////////////////////////////////////////////////////////////
                            State Changing Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev sender sends this transaction with _duration parameter
    function lockAmount(uint _duration) public payable {
        require(msg.value >= getMinLockAmountRequired(), 'Not enough eth was sent');
        require(_duration > getMinLockDurationRequired(), 'Duration should be set atleast to min allowed');
        require(senderToDuration[msg.sender] == 0, 'You already have funds locked, please try with different account');

        senderToAmount[msg.sender] = msg.value;
        senderToDuration[msg.sender] = block.timestamp + _duration;
        emit AmountLocked(msg.sender, msg.value);
    }

    /// @dev sender sends this transaction to withdraw the amount, only executed when duration is complete
    function withdrawAmount() public {
        require(block.timestamp > senderToDuration[msg.sender], 'You cannot remove funds until end of duration');
        require(senderToAmount[msg.sender] > 0, 'Deposit first then you can withdraw');

        (bool sent, ) = msg.sender.call{value: senderToAmount[msg.sender]}("");
        require(sent, "Failed to send Ether");
        senderToAmount[msg.sender] = 0;
        senderToDuration[msg.sender] = 0;
        emit AmountWithdrawn(msg.sender, senderToAmount[msg.sender]);
    }


    /*///////////////////////////////////////////////////////////////
                            Owner Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Owner changes min lock amount required
    function setMinLockAmountRequired(uint _newAmount) public onlyOwner {
        MIN_LOCK_AMOUNT = _newAmount;
        emit MinLockAmountModified(_newAmount);
    }

    /// @dev Owner changes min duration value required
    function setMinLockDurationRequired(uint _newDuration) public onlyOwner {
        MIN_LOCK_DURATION = _newDuration;
        emit MinLockDurationModified(_newDuration);
    }
}
