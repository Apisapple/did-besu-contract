// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../data/ZKPLibrary.sol";

/**
 * @title ZKPStorage
 * @dev Storage contract for Zero-Knowledge Proof (ZKP) credential definitions and schemas.
 *      Provides registration, retrieval, and removal of credential definitions and schemas.
 */
contract ZKPStorage is Initializable {
    using ZKPLibrary for *;

    /// @notice Emitted when the ZKPStorage contract is initialized
    event ZKPStorageSetup();
    /// @notice Emitted when OpenDID access is configured
    event OpenDIDAccessSet(address openDIDAddress);

    address private _openDIDAddress;

    constructor() {
        _disableInitializers();
    }

    modifier onlyOpenDID() {
        require(msg.sender == _openDIDAddress, "ZKPStorage: Caller is not OpenDID");
        _;
    }

    /**
     * @notice Set OpenDID contract address (one-time)
     */
    function setOpenDIDAddress(address openDIDAddress) external {
        require(openDIDAddress != address(0), "ZKPStorage: Invalid OpenDID address");
        require(_openDIDAddress == address(0), "ZKPStorage: OpenDID already set");
        require(msg.sender == openDIDAddress, "ZKPStorage: Caller mismatch");

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
        emit ZKPStorageSetup();
    }

    /**
     * @notice Check if the contract is initialized
     * @return True if the contract is initialized
     */
    function hasInitialized() public view returns (bool) {
        return _getInitializedVersion() > 0;
    }

    struct Storage {
        mapping(string => ZKPLibrary.CredentialDefinition) _credentialDefinitions;
        mapping(string => ZKPLibrary.CredentialSchema) _credentialSchemas;
    }
    bytes32 internal constant STORAGE_LOCATION =
        keccak256("openDID.storage.ZKPStorage");

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
     * @notice Register a new credential definition
     * @param _credentialDefinition The credential definition to register
     */
    function registerCredentialDefinition(
        ZKPLibrary.CredentialDefinition calldata _credentialDefinition
    ) external onlyOpenDID {
        Storage storage store = _getStorage();
        store._credentialDefinitions[
            _credentialDefinition.id
        ] = _credentialDefinition;
    }

    /**
     * @notice Get a credential definition by ID
     * @param _credentialDefinitionId The credential definition ID
     * @return The credential definition struct
     */
    function getCredentialDefinition(
        string calldata _credentialDefinitionId
    ) external view returns (ZKPLibrary.CredentialDefinition memory) {
        Storage storage store = _getStorage();
        return store._credentialDefinitions[_credentialDefinitionId];
    }

    /**
     * @notice Remove a credential definition by ID
     * @param _credentialDefinitionId The credential definition ID
     */
    function removeCredentialDefinition(
        string calldata _credentialDefinitionId
    ) external onlyOpenDID {
        Storage storage store = _getStorage();
        delete store._credentialDefinitions[_credentialDefinitionId];
    }

    /**
     * @notice Register a new credential schema
     * @param _schema The credential schema to register
     */
    function registerSchema(
        ZKPLibrary.CredentialSchema calldata _schema
    ) external onlyOpenDID {
        Storage storage store = _getStorage();
        store._credentialSchemas[_schema.id] = _schema;
    }

    /**
     * @notice Get a credential schema by ID
     * @param _schemaId The credential schema ID
     * @return The credential schema struct
     */
    function getSchema(
        string calldata _schemaId
    ) external view returns (ZKPLibrary.CredentialSchema memory) {
        Storage storage store = _getStorage();
        return store._credentialSchemas[_schemaId];
    }

    /**
     * @notice Remove a credential schema by ID
     * @param _schemaId The credential schema ID
     */
    function removeSchema(string calldata _schemaId) external onlyOpenDID {
        Storage storage store = _getStorage();
        delete store._credentialSchemas[_schemaId];
    }
}
