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
        require(bytes(_vcMeta.id).length > 0, "VcMetaStorage: ID of vcmeta cannot be empty");
        LibAppStorage.appStorage()._vcMeta[_vcMeta.id] = _vcMeta;
        emit VCIssued(_vcMeta.id, msg.sender, _vcMeta.issuer.did);
    }

    function getVcmetaData(
        string calldata _id
    ) public view returns (VcMetaLibrary.VcMeta memory) {
        require(bytes(_id).length > 0, "VcMetaStorage: ID of vcmeta cannot be empty");
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(bytes(s._vcMeta[_id].id).length > 0, "VcMetaStorage: VcMeta does not exist");
        return s._vcMeta[_id];
    }

    function updateVcStats(string calldata _vcId, string calldata _status) public {
        _validateTasOrIssuerRole();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        VcMetaLibrary.VcMeta storage vcMeta = s._vcMeta[_vcId];
        VcMetaLibrary.updateVcStatus(vcMeta, _status);
        emit VCStatus(_vcId, msg.sender, _status);
    }

    function registVcSchema(
        VcSchemaMetaLibrary.VcSchema calldata _vcSchema
    ) public {
        require(bytes(_vcSchema.id).length > 0, "Schema ID cannot be empty");
        require(bytes(_vcSchema.schema).length > 0, "Schema URL cannot be empty");
        require(bytes(_vcSchema.title).length > 0, "Schema title cannot be empty");

        _validateTasOrIssuerRole();

        LibAppStorage.appStorage()._vcSchemas[_vcSchema.id] = _vcSchema;
        emit VCSchemaCreated(_vcSchema.id, msg.sender);
    }

    function getVcSchema(
        string calldata _id
    ) public view returns (VcSchemaMetaLibrary.VcSchema memory) {
        require(bytes(_id).length > 0, "VcMetaStorage: ID of vcschema cannot be empty");
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(bytes(s._vcSchemas[_id].id).length > 0, "VcMetaStorage: VcSchema does not exist");
        return s._vcSchemas[_id];
    }

    function _validateTasOrIssuerRole() internal view {
        bool isTas = LibAppStorage.appStorage().roles[RoleLibrary.TAS][msg.sender];
        bool isIssuer = LibAppStorage.appStorage().roles[RoleLibrary.ISSUER][msg.sender];
        require(isTas || isIssuer, "Caller does not have TAS or Issuer role");
    }
}
