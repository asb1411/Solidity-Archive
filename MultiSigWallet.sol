// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//  ==========  Multi Signature Wallet Contract    ==========

contract MultiSigWallet {

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    // @dev emitted when a deposit to the wallet is made
    event Deposit(address indexed sender, uint amount, uint balance);

    // @dev emitted when a transaction is submitted by any one of the owner
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );

    // @dev emitted when transaction is confirmed by an owner
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);

    // @dev emitted when a transaction is revoked by an owner
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);

    // @dev emitted when a confirmed transaction is executed by any owner
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    // Owner address array
    address[] public owners;

    // Mapping of address to isOwner
    mapping(address => bool) public isOwner;

    // Number of confirmations required for succesful transaction
    uint public numConfirmationsRequired;

    // Transaction structure
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // Transaction array to hold all transactions
    Transaction[] public transactions;

    /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    // Checking for owner
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Message sender not an owner");
        _;
    }

    // Checking if transaction already exists
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    // Checking if transaction is already executed
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    // Checking if transaction is already
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory _owners, uint _numConfirmations) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmations > 0 &&
                _numConfirmations <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Zero address not allowed");
            require(!isOwner[owner], "owner already present");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmations;
    }

    /*///////////////////////////////////////////////////////////////
                            Receive
    //////////////////////////////////////////////////////////////*/

    // Accepting payments
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /*///////////////////////////////////////////////////////////////
                            Getter Functions
    //////////////////////////////////////////////////////////////*/

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    /*///////////////////////////////////////////////////////////////
                            State Changing Functions
    //////////////////////////////////////////////////////////////*/

    // Submitting transaction data sent in transaction is also forwarded
    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // Confirming transaction
    function confirmTransaction(uint _txIndex) public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // Executing Transaction
    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // Revoked already confirmed transaction
    function revokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }
}

