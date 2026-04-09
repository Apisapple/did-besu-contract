// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../libraries/LibAppStorage.sol";
import "../../data/ZKPLibrary.sol";
import "../../data/RoleLibrary.sol";

contract OpenDIDZKPFacet {
    function registZKPCredential(
        ZKPLibrary.CredentialSchema calldata _credentialSchema
    ) public {
        _validateIssuerRole();
        LibAppStorage.appStorage()._credentialSchemas[_credentialSchema.id] = _credentialSchema;
    }

    function getZKPCredential(
        string calldata _id
    ) public view returns (ZKPLibrary.CredentialSchema memory) {
        return LibAppStorage.appStorage()._credentialSchemas[_id];
    }

    function registZKPCredentialDefinition(
        ZKPLibrary.CredentialDefinition calldata _credentialDefinition
    ) public {
        _validateIssuerRole();
        LibAppStorage.appStorage()._credentialDefinitions[_credentialDefinition.id] = _credentialDefinition;
    }

    function getZKPCredentialDefinition(
        string calldata _id
    ) public view returns (ZKPLibrary.CredentialDefinition memory) {
        return LibAppStorage.appStorage()._credentialDefinitions[_id];
    }

    function _validateIssuerRole() internal view {
        require(
            LibAppStorage.appStorage().roles[RoleLibrary.ISSUER][msg.sender],
            "Caller does not have Issuer role"
        );
    }
}
