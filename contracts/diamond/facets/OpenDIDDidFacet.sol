// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../libraries/LibAppStorage.sol";
import "../../data/DocumentLibrary.sol";
import "../../data/RoleLibrary.sol";

contract OpenDIDDidFacet {
    event DIDCreated(string did, address controller);

    function registDidDoc(
        DocumentLibrary.Document calldata _invokedDidDoc
    ) public returns (string memory) {
        _validateTasRole();

        try LibAppStorage.appStorage().documentStorage.registerDocument(_invokedDidDoc, msg.sender) returns (bool isSuccess) {
            require(isSuccess, "Document registration failed");
            emit DIDCreated(_invokedDidDoc.id, msg.sender);
            return DocumentLibrary.documentToJson(_invokedDidDoc);
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during document registration");
        }
    }

    function getDidDoc(
        string calldata _did
    ) public view returns (DocumentLibrary.DocumentAndStatus memory) {
        try LibAppStorage.appStorage().documentStorage.getDocument(_did) returns (
            DocumentLibrary.DocumentAndStatus memory documentAndStatus
        ) {
            return documentAndStatus;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during document retrieval");
        }
    }

    function getDidDocStatus(
        string calldata _did
    ) public view returns (DocumentLibrary.DocumentStatus memory) {
        require(bytes(_did).length > 0, "DocumentStorage: Document ID cannot be empty");
        return LibAppStorage.appStorage().documentStorage.getDocumentStatus(_did);
    }

    function updateDidDocStatusInService(
        string calldata _did,
        string calldata _status,
        string calldata _versionId
    ) public {
        _validateTasRole();

        try LibAppStorage.appStorage().documentStorage.getDocument(_did, _versionId) returns (
            DocumentLibrary.Document memory document
        ) {
            require(bytes(_did).length > 0, "DocumentStorage: Document id cannot be empty");
            require(bytes(_status).length > 0, "DocumentStorage: Document status cannot be empty");

            DocumentLibrary.setActivated(document, _status);
            LibAppStorage.appStorage().documentStorage.updateDocument(document, _did, _versionId);
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during document retrieval");
        }
    }

    function updateDidDocStatusRevocation(
        string calldata _did,
        string calldata _status,
        string calldata _terminatedTime
    ) public {
        _validateTasRole();

        try LibAppStorage.appStorage().documentStorage.getDocumentStatus(_did) returns (
            DocumentLibrary.DocumentStatus memory documentStatus
        ) {
            DocumentLibrary.updateStatus(documentStatus, _status, _terminatedTime);
            LibAppStorage.appStorage().documentStorage.updateDocumentStatus(documentStatus, _did);
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during document retrieval");
        }
    }

    function _validateTasRole() internal view {
        require(
            LibAppStorage.appStorage().roles[RoleLibrary.TAS][msg.sender],
            "Caller does not have TAS role"
        );
    }
}
