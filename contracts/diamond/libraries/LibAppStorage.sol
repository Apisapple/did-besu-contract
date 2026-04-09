// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../data/DocumentLibrary.sol";
import "../../data/VcMetaLibrary.sol";
import "../../data/VcSchemaMetaLibrary.sol";
import "../../data/ZKPLibrary.sol";

library LibAppStorage {
    bytes32 internal constant APP_STORAGE_POSITION =
        keccak256("opendid.diamond.app.storage");

    struct AppStorage {
        // Document storage
        mapping(string => DocumentLibrary.Document) _doc;
        mapping(string => DocumentLibrary.DocumentStatus) _docStatus;
        mapping(address => string[]) _documentIds;
        // VcMeta storage
        mapping(string => VcMetaLibrary.VcMeta) _vcMeta;
        mapping(string => VcSchemaMetaLibrary.VcSchema) _vcSchemas;
        // ZKP storage
        mapping(string => ZKPLibrary.CredentialDefinition) _credentialDefinitions;
        mapping(string => ZKPLibrary.CredentialSchema) _credentialSchemas;
        // Access control
        mapping(bytes32 => mapping(address => bool)) roles;
        bool initialized;
    }

    function appStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
