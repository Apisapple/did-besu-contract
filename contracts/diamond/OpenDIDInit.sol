// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./libraries/LibAppStorage.sol";
import "../data/RoleLibrary.sol";

contract OpenDIDInit {
    event Setup();

    function init(
        address _documentStorage,
        address _vcMetaStorage,
        address _zkpStorage,
        address _multibaseContract,
        address _admin
    ) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(!s.initialized, "OpenDIDInit: already initialized");

        require(_documentStorage != address(0), "Invalid DocumentStorage address");
        require(_vcMetaStorage != address(0), "Invalid VcMetaStorage address");
        require(_zkpStorage != address(0), "Invalid ZKPStorage address");
        require(_multibaseContract != address(0), "Invalid MultibaseContract address");
        require(_admin != address(0), "Invalid admin address");

        s.documentStorage = DocumentStorage(_documentStorage);
        s.vcMetaStorage = VcMetaStorage(_vcMetaStorage);
        s.zkpStorage = ZKPStorage(_zkpStorage);
        s.multibaseContract = MultibaseContract(_multibaseContract);
        s.roles[RoleLibrary.ADMIN_ROLE][_admin] = true;
        s.initialized = true;

        s.documentStorage.setOpenDIDAddress(address(this));
        s.vcMetaStorage.setOpenDIDAddress(address(this));
        s.zkpStorage.setOpenDIDAddress(address(this));

        emit Setup();
    }
}
