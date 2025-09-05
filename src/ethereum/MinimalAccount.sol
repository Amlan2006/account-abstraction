// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
contract MinimalAccount is IAccount,Ownable {
    error NotFromEntryPoint();
    error NotFromEntryPointOrOwner();
    error CallFailed();
     modifier onlyFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert NotFromEntryPoint();
        }
        _;
    }
    modifier onlyFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert NotFromEntryPointOrOwner();
        }
        _;
    }
    IEntryPoint private immutable i_entryPoint;
    constructor(address entrypoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entrypoint);
    }
    receive() external payable {}
    function execute(address dest, uint256 value, bytes calldata functionData) external onlyFromEntryPointOrOwner{
        (bool success, bytes memory result) = dest.call{value: value}(functionData);
        if(!success){
            revert CallFailed();
        }
    }
   function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData){
        _validateSignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if(signer != owner()){
return 1;
        }
        return 0;
        
    }
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            (bool success, ) = payable(msg.sender).call{value: missingAccountFunds,gas: type(uint256).max}("");
            require(success, "prefund failed");
        }
    }
    function getEntryPoint() public view returns (address) {
        return address(i_entryPoint);
    }
}