// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../libraries/LibAppStorage.sol";
import "../../data/RoleLibrary.sol";

contract OpenDIDAdminFacet {
    function hasInitialized() public view returns (bool) {
        return LibAppStorage.appStorage().initialized;
    }

    function registRole(address target, string calldata roleType) public {
        _validateRole(RoleLibrary.ADMIN_ROLE);
        require(target != address(0), "Target address cannot be zero");
        require(bytes(roleType).length > 0, "Role type cannot be empty");

        bytes32 role = keccak256(abi.encodePacked(roleType));
        LibAppStorage.appStorage().roles[role][target] = true;
    }

    function isHaveRole(address target, string calldata roleType) public view returns (bool) {
        require(target != address(0), "Target address cannot be zero");
        require(bytes(roleType).length > 0, "Role type cannot be empty");

        bytes32 role = keccak256(abi.encodePacked(roleType));
        return LibAppStorage.appStorage().roles[role][target];
    }

    function _validateRole(bytes32 role) internal view {
        require(LibAppStorage.appStorage().roles[role][msg.sender], "Access denied");
    }
}
