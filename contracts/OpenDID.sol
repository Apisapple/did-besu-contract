// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./data/ZKPLibrary.sol";
import "./data/DocumentLibrary.sol";
import "./data/VcMetaLibrary.sol";
import "./data/VcSchemaMetaLibrary.sol";
import "./data/RoleLibrary.sol";

import "./storage/DocumentStorage.sol";
import "./storage/VcMetaStorage.sol";
import "./storage/ZKPStorage.sol";

import "./crypto/MultibaseContract.sol";

/**
 * @title OpenDID
 * @dev Smart contract for managing DIDs, VCs, and ZKP credentials with role-based access control.
 * It provides document and credential registration, status management, and integration with multibase encoding/decoding.
 */
contract OpenDID is Initializable, UUPSUpgradeable, AccessControl {
    // Event declaration
    // Emitted when the contract is initialized
    event Setup();
    // Emitted when a new DID is created
    event DIDCreated(string did, address controller);
    // Emitted when a DID is updated
    event DIDUpdated(string did, address controller);
    // Emitted when a DID is deactivated
    event DIDDeactivated(string did, address controller);
    // Emitted when a Verifiable Credential is issued
    event VCIssued(string vcId, address issuer, string did);
    // Emitted when a VC status is updated
    event VCStatus(string vcId, address player, string status);
    // Emitted when a VC schema is created
    event VCSchemaCreated(string schemaId, address issuer);

    // Libraries
    // Using library functions for Document, VcMeta, VcSchema, CredentialSchema, and CredentialDefinition
    using DocumentLibrary for DocumentLibrary.Document;
    using VcMetaLibrary for VcMetaLibrary.VcMeta;
    using VcSchemaMetaLibrary for VcSchemaMetaLibrary.VcSchema;
    using ZKPLibrary for ZKPLibrary.CredentialSchema;
    using ZKPLibrary for ZKPLibrary.CredentialDefinition;

    // Storage contracts
    // Storage for documents, VC metadata, and ZKP credentials
    DocumentStorage private documentStorage;
    VcMetaStorage private vcMetaStorage;
    ZKPStorage private zkpStorage;

    // Multibase contract for encoding/decoding public keys
    MultibaseContract private multibaseContract;

    /**
     * @dev Initializes the contract with storage and multibase contract addresses.
     * Grants ADMIN_ROLE to the deployer.
     */
    function initialize(
        address _documentStorage,
        address _vcMetaStorage,
        address _zkpStorage,
        address _multibaseContract
    ) public initializer {
        _grantRole(RoleLibrary.ADMIN_ROLE, _msgSender());
        __UUPSUpgradeable_init();

        require(
            _documentStorage != address(0),
            "Invalid DocumentStorage address"
        );

        require(_vcMetaStorage != address(0), "Invalid VcMetaStorage address");
        require(_zkpStorage != address(0), "Invalid ZKPStorage address");

        documentStorage = DocumentStorage(_documentStorage);
        vcMetaStorage = VcMetaStorage(_vcMetaStorage);
        zkpStorage = ZKPStorage(_zkpStorage);
        multibaseContract = MultibaseContract(_multibaseContract);

        documentStorage.setOpenDIDAddress(address(this));
        vcMetaStorage.setOpenDIDAddress(address(this));
        zkpStorage.setOpenDIDAddress(address(this));

        emit Setup();
    }

    /**
     * @dev Returns true if the contract has been initialized.
     */
    function hasInitialized() public view returns (bool) {
        return _getInitializedVersion() > 0;
    }

    /**
     * @dev Authorizes contract upgrades. Only ADMIN_ROLE can upgrade.
     */
    function _authorizeUpgrade(
        address newImplement
    ) internal override onlyRole(RoleLibrary.ADMIN_ROLE) {}

    /**
     * @dev Sets the DocumentStorage contract address. Only ADMIN_ROLE can call.
     */
    function setDocumentStorage(
        address _documentStorage
    ) public onlyRole(RoleLibrary.ADMIN_ROLE) {
        documentStorage = DocumentStorage(_documentStorage);
    }

    /**
     * @dev Sets the VcMetaStorage contract address. Only ADMIN_ROLE can call.
     */
    function setVcMetaStorage(
        address _vcMetaStorage
    ) public onlyRole(RoleLibrary.ADMIN_ROLE) {
        vcMetaStorage = VcMetaStorage(_vcMetaStorage);
    }

    /**
     * @dev Sets the ZKPStorage contract address. Only ADMIN_ROLE can call.
     */
    function setZKPStorage(
        address _zkpStorage
    ) public onlyRole(RoleLibrary.ADMIN_ROLE) {
        zkpStorage = ZKPStorage(_zkpStorage);
    }

    /**
     * @dev Grants a role to a target address. Only ADMIN_ROLE can call.
     * @param target The address to grant the role to.
     * @param roleType The string identifier of the role.
     */
    function registRole(
        address target,
        string calldata roleType
    ) public onlyRole(RoleLibrary.ADMIN_ROLE) {
        require(target != address(0), "Target address cannot be zero");
        require(bytes(roleType).length > 0, "Role type cannot be empty");
        _grantRole(keccak256(abi.encodePacked(roleType)), target);
    }

    /**
     * @dev Checks if a target address has a specific role.
     * @param target The address to check.
     * @param roleType The string identifier of the role.
     * @return True if the address has the role, false otherwise.
     */
    function isHaveRole(
        address target,
        string calldata roleType
    ) public view returns (bool) {
        require(target != address(0), "Target address cannot be zero");
        require(bytes(roleType).length > 0, "Role type cannot be empty");
        return hasRole(keccak256(abi.encodePacked(roleType)), target);
    }

    /**
     * @dev Registers a new DID Document.
     * @param _invokedDidDoc The DID Document to register.
     * @return The registered document as a JSON string.
     */
    function registDidDoc(
        DocumentLibrary.Document calldata _invokedDidDoc
    ) public returns (string memory) {
        validateTasRole();

        try
            documentStorage.registerDocument(_invokedDidDoc, msg.sender)
        returns (bool isSuccess) {
            require(isSuccess, "Document registration failed");

            // Emit event and assign role
            emit DIDCreated(_invokedDidDoc.id, msg.sender);

            // Return the document as JSON
            return DocumentLibrary.documentToJson(_invokedDidDoc);
        } catch Error(string memory reason) {
            revert(reason); // Revert with the specific error reason
        } catch {
            revert("Unknown error occurred during document registration");
        }
    }

    /**
     * @dev Retrieves a DID Document and its status by DID.
     * @param _did The DID to query.
     * @return The DocumentAndStatus struct.
     */
    function getDidDoc(
        string calldata _did
    ) public view returns (DocumentLibrary.DocumentAndStatus memory) {
        // Try to retrieve the DID Document from the storage contract
        try documentStorage.getDocument(_did) returns (
            DocumentLibrary.DocumentAndStatus memory documentAndStatus
        ) {
            // Return a successful response with the document data
            return documentAndStatus;
            // Catch and handle specific errors thrown by the storage contract
        } catch Error(string memory reason) {
            // Revert the transaction with the specific error reason
            revert(reason);
        } catch {
            // Revert the transaction with a generic error message
            revert("Unknown error occurred during document retrieval");
        }
    }

    /**
     * @dev Retrieves the status of a DID Document.
     * @param _did The DID to query.
     * @return The DocumentStatus struct.
     */
    function getDidDocStatus(
        string calldata _did
    ) public view returns (DocumentLibrary.DocumentStatus memory) {
        require(
            bytes(_did).length > 0,
            "DocumentStorage: Document ID cannot be empty"
        );

        DocumentLibrary.DocumentStatus memory documentStatus = documentStorage
            .getDocumentStatus(_did);
        return documentStatus;
    }

    /**
     * @dev Updates the status of a DID Document in service.
     * @param _did The DID to update.
     * @param _status The new status.
     * @param _versionId The version ID of the document.
     */
    function updateDidDocStatusInService(
        string calldata _did,
        string calldata _status,
        string calldata _versionId
    ) public {
        validateTasRole();

        try documentStorage.getDocument(_did, _versionId) returns (
            DocumentLibrary.Document memory document
        ) {
            // check params
            require(
                bytes(_did).length > 0,
                "DocumentStorage: Document id cannot be empty"
            );
            require(
                bytes(_status).length > 0,
                "DocumentStorage: Document status cannot be empty"
            );

            // update document status
            DocumentLibrary.setActivated(document, _status);

            // store document status
            documentStorage.updateDocument(document, _did, _versionId);
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during document retrieval");
        }
    }

    /**
     * @dev Updates the status of a DID Document for revocation.
     * @param _did The DID to update.
     * @param _status The new status.
     * @param _terminatedTime The time of termination.
     */
    function updateDidDocStatusRevocation(
        string calldata _did,
        string calldata _status,
        string calldata _terminatedTime
    ) public {
        validateTasRole();

        try documentStorage.getDocumentStatus(_did) returns (
            DocumentLibrary.DocumentStatus memory documentStatus
        ) {
            // 문서 상태 업데이트
            DocumentLibrary.updateStatus(
                documentStatus,
                _status,
                _terminatedTime
            );

            // 문서 상태 저장
            documentStorage.updateDocumentStatus(documentStatus, _did);
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during document retrieval");
        }
    }

    /**
     * @dev Registers Verifiable Credential metadata.
     * @param _vcMeta The VC metadata to register.
     */
    function registVcMetaData(VcMetaLibrary.VcMeta calldata _vcMeta) public {
        validateTasOrIssuerRole();

        vcMetaStorage.registerVcMeta(_vcMeta);
        emit VCIssued(_vcMeta.id, msg.sender, _vcMeta.issuer.did);
    }

    /**
     * @dev Retrieves Verifiable Credential metadata by ID.
     * @param _id The VC ID to query.
     * @return The VcMeta struct.
     */
    function getVcmetaData(
        string calldata _id
    ) public view returns (VcMetaLibrary.VcMeta memory) {
        try vcMetaStorage.getVcMeta(_id) returns (
            VcMetaLibrary.VcMeta memory vcMeta
        ) {
            return vcMeta;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during VC metadata retrieval");
        }
    }

    /**
     * @dev Updates the status of a Verifiable Credential.
     * @param _vcId The VC ID to update.
     * @param _status The new status.
     */
    function updateVcStats(
        string calldata _vcId,
        string calldata _status
    ) public {
        validateTasOrIssuerRole();

        vcMetaStorage.updateVcMetaStatus(_vcId, _status);
        emit VCStatus(_vcId, msg.sender, _status);
    }

    /**
     * @dev Registers a new VC schema.
     * @param _vcSchema The VC schema to register.
     */
    function registVcSchema(
        VcSchemaMetaLibrary.VcSchema calldata _vcSchema
    ) public {
        require(bytes(_vcSchema.id).length > 0, "Schema ID cannot be empty");
        require(
            bytes(_vcSchema.schema).length > 0,
            "Schema URL cannot be empty"
        );
        require(
            bytes(_vcSchema.title).length > 0,
            "Schema title cannot be empty"
        );

        validateTasOrIssuerRole();

        vcMetaStorage.registerVcSchema(_vcSchema);
        emit VCSchemaCreated(_vcSchema.id, msg.sender);
    }

    /**
     * @dev Retrieves a VC schema by ID.
     * @param _id The schema ID to query.
     * @return The VcSchema struct.
     */
    function getVcSchema(
        string calldata _id
    ) public view returns (VcSchemaMetaLibrary.VcSchema memory) {
        try vcMetaStorage.getVcSchema(_id) returns (
            VcSchemaMetaLibrary.VcSchema memory vcSchema
        ) {
            return vcSchema;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during VC schema retrieval");
        }
    }

    /**
     * @dev Registers a new ZKP credential schema.
     * @param _credentialSchema The credential schema to register.
     */
    function registZKPCredential(
        ZKPLibrary.CredentialSchema calldata _credentialSchema
    ) public {
        validateIssuerRole();

        zkpStorage.registerSchema(_credentialSchema);
    }

    /**
     * @dev Retrieves a ZKP credential schema by ID.
     * @param _id The schema ID to query.
     * @return The CredentialSchema struct.
     */
    function getZKPCredential(
        string calldata _id
    ) public view returns (ZKPLibrary.CredentialSchema memory) {
        try zkpStorage.getSchema(_id) returns (
            ZKPLibrary.CredentialSchema memory credentialSchema
        ) {
            return credentialSchema;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error occurred during ZKP credential retrieval");
        }
    }

    /**
     * @dev Registers a new ZKP credential definition.
     * @param _credentialDefinition The credential definition to register.
     */
    function registZKPCredentialDefinition(
        ZKPLibrary.CredentialDefinition calldata _credentialDefinition
    ) public {
        validateIssuerRole();
        zkpStorage.registerCredentialDefinition(_credentialDefinition);
    }

    /**
     * @dev Retrieves a ZKP credential definition by ID.
     * @param _id The definition ID to query.
     * @return The CredentialDefinition struct.
     */
    function getZKPCredentialDefinition(
        string calldata _id
    ) public view returns (ZKPLibrary.CredentialDefinition memory) {
        try zkpStorage.getCredentialDefinition(_id) returns (
            ZKPLibrary.CredentialDefinition memory credentialDefinition
        ) {
            return credentialDefinition;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert(
                "Unknown error occurred during ZKP credential definition retrieval"
            );
        }
    }

    function validateTasRole() internal view {
        require(
            hasRole(RoleLibrary.TAS, msg.sender),
            "Caller does not have TAS role"
        );
    }

    function validateIssuerRole() internal view {
        require(
            hasRole(RoleLibrary.ISSUER, msg.sender),
            "Caller does not have Issuer role"
        );
    }

    function validateTasOrIssuerRole() internal view {
        require(
            hasRole(RoleLibrary.TAS, msg.sender) ||
                hasRole(RoleLibrary.ISSUER, msg.sender),
            "Caller does not have TAS or Issuer role"
        );
    }
}
