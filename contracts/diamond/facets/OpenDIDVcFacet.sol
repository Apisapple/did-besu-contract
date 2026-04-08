// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../libraries/LibAppStorage.sol";
import "../../data/VcMetaLibrary.sol";
import "../../data/VcSchemaMetaLibrary.sol";
import "../../data/RoleLibrary.sol";

contract OpenDIDVcFacet {
    event VCIssued(string vcId, address issuer, string did);
    event VCStatus(string vcId, address player, string status);
    event VCSchemaCreated(string schemaId, address issuer);

    function registVcMetaData(VcMetaLibrary.VcMeta calldata _vcMeta) public {
        _validateTasOrIssuerRole();
        LibAppStorage.appStorage().vcMetaStorage.registerVcMeta(_vcMeta);
        emit VCIssued(_vcMeta.id, msg.sender, _vcMeta.issuer.did);
    }

    function getVcmetaData(
        string calldata _id
    ) public view returns (VcMetaLibrary.VcMeta memory) {
        try LibAppStorage.appStorage().vcMetaStorage.getVcMeta(_id) returns (
            VcMetaLibrary.VcMeta memory vcMeta
        ) {
            return vcMeta;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during VC metadata retrieval");
        }
    }

    function updateVcStats(string calldata _vcId, string calldata _status) public {
        _validateTasOrIssuerRole();
        LibAppStorage.appStorage().vcMetaStorage.updateVcMetaStatus(_vcId, _status);
        emit VCStatus(_vcId, msg.sender, _status);
    }

    function registVcSchema(
        VcSchemaMetaLibrary.VcSchema calldata _vcSchema
    ) public {
        require(bytes(_vcSchema.id).length > 0, "Schema ID cannot be empty");
        require(bytes(_vcSchema.schema).length > 0, "Schema URL cannot be empty");
        require(bytes(_vcSchema.title).length > 0, "Schema title cannot be empty");

        _validateTasOrIssuerRole();

        LibAppStorage.appStorage().vcMetaStorage.registerVcSchema(_vcSchema);
        emit VCSchemaCreated(_vcSchema.id, msg.sender);
    }

    function getVcSchema(
        string calldata _id
    ) public view returns (VcSchemaMetaLibrary.VcSchema memory) {
        try LibAppStorage.appStorage().vcMetaStorage.getVcSchema(_id) returns (
            VcSchemaMetaLibrary.VcSchema memory vcSchema
        ) {
            return vcSchema;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during VC schema retrieval");
        }
    }

    function _validateTasOrIssuerRole() internal view {
        bool isTas = LibAppStorage.appStorage().roles[RoleLibrary.TAS][msg.sender];
        bool isIssuer = LibAppStorage.appStorage().roles[RoleLibrary.ISSUER][msg.sender];
        require(isTas || isIssuer, "Caller does not have TAS or Issuer role");
    }
}
