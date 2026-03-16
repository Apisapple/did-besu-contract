// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../data/VcMetaLibrary.sol";
import "../data/VcSchemaMetaLibrary.sol";

/**
 * @title VcMetaStorage
 * @dev Storage contract for Verifiable Credential (VC) metadata and VC schemas.
 *      Provides registration, retrieval, update, and deletion of VC metadata and schemas.
 */
contract VcMetaStorage is Initializable {
    using VcMetaLibrary for VcMetaLibrary.VcMeta;
    using VcSchemaMetaLibrary for VcSchemaMetaLibrary.VcSchema;

    /// @notice Emitted when the VcMetaStorage contract is initialized
    event VcMetaStorageSetup();
    /// @notice Emitted when a VC metadata or schema is registered
    event VcMetaRegistered(string _id, string _vcMetaJson);
    /// @notice Emitted when OpenDID access is configured
    event OpenDIDAccessSet(address openDIDAddress);
    /// @notice Emitted when VC metadata status is updated
    event VcMetaStatusUpdated(string vcId, string status);
    /// @notice Emitted when VC schema is deleted
    event VcSchemaDeleted(string vcSchemaId);

    address private _openDIDAddress;

    constructor() {
        _disableInitializers();
    }

    modifier onlyOpenDID() {
        require(msg.sender == _openDIDAddress, "VcMetaStorage: Caller is not OpenDID");
        _;
    }

    /**
     * @notice Set OpenDID contract address (one-time)
     */
    function setOpenDIDAddress(address openDIDAddress) external {
        require(openDIDAddress != address(0), "VcMetaStorage: Invalid OpenDID address");
        require(_openDIDAddress == address(0), "VcMetaStorage: OpenDID already set");
        require(msg.sender == openDIDAddress, "VcMetaStorage: Caller mismatch");

        _openDIDAddress = openDIDAddress;
        emit OpenDIDAccessSet(openDIDAddress);
    }

    function getOpenDIDAddress() external view returns (address) {
        return _openDIDAddress;
    }

    /**
     * @notice Initialize the storage contract
     */
    function initialize() public initializer {
        emit VcMetaStorageSetup();
    }

    /**
     * @notice Check if the contract is initialized
     * @return True if the contract is initialized
     */
    function hasInitialized() public view returns (bool) {
        return _getInitializedVersion() > 0;
    }

    struct Storage {
        mapping(string => VcMetaLibrary.VcMeta) _vcMeta;
        mapping(string => VcSchemaMetaLibrary.VcSchema) _vcSchemas;
    }

    bytes32 internal constant STORAGE_LOCATION =
        keccak256("openDID.storage.VcMetaStorage");

    /**
     * @dev Returns the storage struct pointer for this contract
     */
    function _getStorage() private pure returns (Storage storage store) {
        bytes32 position = STORAGE_LOCATION;
        assembly {
            store.slot := position
        }
    }

    /**
     * @notice Register a new VC metadata
     * @param _vcMeta The VC metadata to register
     */
    function registerVcMeta(VcMetaLibrary.VcMeta calldata _vcMeta) external onlyOpenDID {
        Storage storage store = _getStorage();

        require(
            bytes(_vcMeta.id).length > 0,
            "VcMetaStorage: ID of vcmeta cannot be empty"
        );
        store._vcMeta[_vcMeta.id] = _vcMeta;

        string memory vcMetaJson = VcMetaLibrary.toJson(_vcMeta);
        emit VcMetaRegistered(_vcMeta.id, vcMetaJson);
    }

    /**
     * @notice Get VC metadata by ID
     * @param _vcMetaId The VC metadata ID
     * @return The VC metadata struct
     */
    function getVcMeta(
        string calldata _vcMetaId
    ) external view returns (VcMetaLibrary.VcMeta memory) {
        Storage storage store = _getStorage();

        require(
            bytes(_vcMetaId).length > 0,
            "VcMetaStorage: ID of vcmeta cannot be empty"
        );

        require(_isExist(_vcMetaId), "VcMetaStorage: VcMeta does not exist");

        return store._vcMeta[_vcMetaId];
    }

    /**
     * @dev Checks if a VC metadata exists by ID
     * @param _id The VC metadata ID
     * @return True if exists, false otherwise
     */
    function _isExist(string calldata _id) internal view returns (bool) {
        Storage storage store = _getStorage();
        // Check if the data exists
        return bytes(store._vcMeta[_id].id).length > 0;
    }

    /**
     * @notice Update the status of a VC metadata
     * @param _vcId The VC ID
     * @param _status The new status ("active", "inactive", "revoked")
     */
    function updateVcMetaStatus(
        string calldata _vcId,
        string calldata _status
    ) external onlyOpenDID {
        Storage storage store = _getStorage();
        VcMetaLibrary.VcMeta storage vcMeta = store._vcMeta[_vcId];
        VcMetaLibrary.updateVcStatus(vcMeta, _status);

        store._vcMeta[_vcId] = vcMeta;
        emit VcMetaStatusUpdated(_vcId, _status);
    }

    /**
     * @notice Register a new VC schema
     * @param _vcSchema The VC schema to register
     */
    function registerVcSchema(
        VcSchemaMetaLibrary.VcSchema calldata _vcSchema
    ) external onlyOpenDID {
        Storage storage store = _getStorage();

        require(
            bytes(_vcSchema.id).length > 0,
            "VcMetaStorage: ID of vcschema cannot be empty"
        );

        store._vcSchemas[_vcSchema.id] = _vcSchema;

        string memory vcSchemaJson = VcSchemaMetaLibrary.toJson(_vcSchema);
        emit VcMetaRegistered(_vcSchema.id, vcSchemaJson);
    }

    /**
     * @notice Get VC schema by ID
     * @param _vcSchemaId The VC schema ID
     * @return The VC schema struct
     */
    function getVcSchema(
        string calldata _vcSchemaId
    ) external view returns (VcSchemaMetaLibrary.VcSchema memory) {
        Storage storage store = _getStorage();

        require(
            bytes(_vcSchemaId).length > 0,
            "VcMetaStorage: ID of vcschema cannot be empty"
        );

        require(
            _isExistSchema(_vcSchemaId),
            "VcMetaStorage: VcSchema does not exist"
        );

        return store._vcSchemas[_vcSchemaId];
    }

    /**
     * @dev Checks if a VC schema exists by ID
     * @param _id The VC schema ID
     * @return True if exists, false otherwise
     */
    function _isExistSchema(string calldata _id) internal view returns (bool) {
        Storage storage store = _getStorage();
        // Check if the data exists
        return bytes(store._vcSchemas[_id].id).length > 0;
    }

    /**
     * @notice Delete a VC schema by ID
     * @param _vcSchemaId The VC schema ID
     */
    function deleteVcSchema(string calldata _vcSchemaId) external onlyOpenDID {
        Storage storage store = _getStorage();
        delete store._vcSchemas[_vcSchemaId];
        emit VcSchemaDeleted(_vcSchemaId);
    }
}
