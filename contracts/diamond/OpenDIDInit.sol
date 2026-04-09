// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./libraries/LibAppStorage.sol";
import "../data/RoleLibrary.sol";

contract OpenDIDInit {
    event Setup();

    function init(address _admin) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(!s.initialized, "OpenDIDInit: already initialized");
        require(_admin != address(0), "Invalid admin address");

        s.roles[RoleLibrary.ADMIN_ROLE][_admin] = true;
        s.initialized = true;

        emit Setup();
    }
}
