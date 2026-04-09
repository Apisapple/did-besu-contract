// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../libraries/LibAppStorage.sol";
import "../../data/DocumentLibrary.sol";
import "../../data/RoleLibrary.sol";

contract OpenDIDDidDocFacet {
    event DIDCreated(string did, address controller);

    function registDidDoc(
        DocumentLibrary.Document calldata _invokedDidDoc
    ) public returns (string memory) {
        _validateTasRole();

        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        s._doc[_invokedDidDoc.id] = _invokedDidDoc;
        s._doc[_getVersionedId(_invokedDidDoc.id, _invokedDidDoc.versionId)] = _invokedDidDoc;
        s._docStatus[_invokedDidDoc.id] = DocumentLibrary.DocumentStatus({
            id: _invokedDidDoc.id,
            status: DocumentLibrary.DIDDOC_STATUS.ACTIVATED,
            version: _invokedDidDoc.versionId,
            roleType: "",
            terminatedTime: ""
        });
        s._documentIds[msg.sender].push(_invokedDidDoc.id);

        emit DIDCreated(_invokedDidDoc.id, msg.sender);
        return DocumentLibrary.documentToJson(_invokedDidDoc);
    }

    function getDidDoc(
        string calldata _did
    ) public view returns (DocumentLibrary.DocumentAndStatus memory) {
        require(bytes(_did).length > 0, "DocumentStorage: Document ID cannot be empty");
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(bytes(s._doc[_did].id).length > 0, "Document is not exist");
        return DocumentLibrary.DocumentAndStatus(s._doc[_did], s._docStatus[_did].status);
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
