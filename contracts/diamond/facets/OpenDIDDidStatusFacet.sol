// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../libraries/LibAppStorage.sol";
import "../../data/DocumentLibrary.sol";
import "../../data/RoleLibrary.sol";
import "../../utils/StringUtils.sol";

contract OpenDIDDidStatusFacet {
    event DocumentUpdated(string id, string versionId);
    event DocumentStatusUpdated(string id, DocumentLibrary.DIDDOC_STATUS status);

    function getDidDocStatus(
        string calldata _did
    ) public view returns (DocumentLibrary.DocumentStatus memory) {
        require(bytes(_did).length > 0, "DocumentStorage: Document ID cannot be empty");
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(bytes(s._docStatus[_did].id).length > 0, "Document status is not exist");
        return s._docStatus[_did];
    }

    function updateDidDocStatusInService(
        string calldata _did,
        string calldata _status,
        string calldata _versionId
    ) public {
        _validateTasRole();
        require(bytes(_did).length > 0, "DocumentStorage: Document id cannot be empty");
        require(bytes(_status).length > 0, "DocumentStorage: Document status cannot be empty");

        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        string memory versionedId = bytes(_versionId).length == 0
            ? _did
            : _getVersionedId(_did, _versionId);
        DocumentLibrary.Document memory document = s._doc[versionedId];
        DocumentLibrary.setActivated(document, _status);

        uint256 latestVersion = StringUtils.stringToUint(s._doc[_did].versionId);
        uint256 updatedVersion = StringUtils.stringToUint(document.versionId);
        if (latestVersion <= updatedVersion) {
            s._doc[_did] = document;
        }
        s._doc[_getVersionedId(_did, _versionId)] = document;

        emit DocumentUpdated(_did, _versionId);
    }

    function updateDidDocStatusRevocation(
        string calldata _did,
        string calldata _status,
        string calldata _terminatedTime
    ) public {
        _validateTasRole();

        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(bytes(s._docStatus[_did].id).length > 0, "Document status is not exist");
        DocumentLibrary.DocumentStatus memory documentStatus = s._docStatus[_did];
        DocumentLibrary.updateStatus(documentStatus, _status, _terminatedTime);
        s._docStatus[_did] = documentStatus;

        emit DocumentStatusUpdated(_did, documentStatus.status);
    }

    function _validateTasRole() internal view {
        require(
            LibAppStorage.appStorage().roles[RoleLibrary.TAS][msg.sender],
            "Caller does not have TAS role"
        );
    }

    function _getVersionedId(
        string memory _did,
        string memory _versionId
    ) private pure returns (string memory) {
        return string(abi.encodePacked(_did, _versionId));
    }
}
