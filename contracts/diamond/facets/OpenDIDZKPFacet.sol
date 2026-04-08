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
        LibAppStorage.appStorage().zkpStorage.registerSchema(_credentialSchema);
    }

    function getZKPCredential(
        string calldata _id
    ) public view returns (ZKPLibrary.CredentialSchema memory) {
        try LibAppStorage.appStorage().zkpStorage.getSchema(_id) returns (
            ZKPLibrary.CredentialSchema memory credentialSchema
        ) {
            return credentialSchema;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during ZKP credential retrieval");
        }
    }

    function registZKPCredentialDefinition(
        ZKPLibrary.CredentialDefinition calldata _credentialDefinition
    ) public {
        _validateIssuerRole();
        LibAppStorage.appStorage().zkpStorage.registerCredentialDefinition(
            _credentialDefinition
        );
    }

    function getZKPCredentialDefinition(
        string calldata _id
    ) public view returns (ZKPLibrary.CredentialDefinition memory) {
        try LibAppStorage.appStorage().zkpStorage.getCredentialDefinition(_id) returns (
            ZKPLibrary.CredentialDefinition memory credentialDefinition
        ) {
            return credentialDefinition;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during ZKP credential definition retrieval");
        }
    }

    function _validateIssuerRole() internal view {
        require(
            LibAppStorage.appStorage().roles[RoleLibrary.ISSUER][msg.sender],
            "Caller does not have Issuer role"
        );
    }
}
