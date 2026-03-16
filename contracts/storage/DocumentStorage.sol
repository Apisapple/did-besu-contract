// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../data/DocumentLibrary.sol";
import "../utils/StringUtils.sol";

/**
 * @title DocumentStorage
 * @dev Storage contract for DID documents and their statuses.
 *      Provides registration, retrieval, update, and removal of documents and their statuses.
 */
contract DocumentStorage is Initializable, OwnableUpgradeable {
    using DocumentLibrary for DocumentLibrary.Document;

    // Events
    event DocumentStorageSetup();
    event DocumentRegistered(string id, address controller);
    event DocumentUpdated(string id, string versionId);
    event DocumentRemoved(string id);
    event DocumentStatusUpdated(
        string id,
        DocumentLibrary.DIDDOC_STATUS status
    );
    event OpenDIDAccessSet(address openDIDAddress);

    address private _openDIDAddress;

    /// @custom:storage-location erc7201:openDID.storage.DocumentStorage
    struct Storage {
        mapping(string => DocumentLibrary.Document) _doc;
        mapping(string => DocumentLibrary.DocumentStatus) _docStatus;
        mapping(address => string[]) _documentIds;
    }

    bytes32 internal constant STORAGE_LOCATION =
        keccak256("openDID.storage.DocumentStorage");

    constructor() {
        _disableInitializers();
    }

    modifier onlyOpenDID() {
        require(msg.sender == _openDIDAddress, "DocumentStorage: Caller is not OpenDID");
        _;
    }

    /**
     * @notice Set OpenDID contract address (one-time)
     */
    function setOpenDIDAddress(address openDIDAddress) external {
        require(openDIDAddress != address(0), "DocumentStorage: Invalid OpenDID address");
        require(_openDIDAddress == address(0), "DocumentStorage: OpenDID already set");
        require(msg.sender == openDIDAddress, "DocumentStorage: Caller mismatch");

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
        __Ownable_init(msg.sender);
        emit DocumentStorageSetup();
    }

    /**
     * @notice Check if the contract is initialized
     * @return True if the contract is initialized
     */
    function hasInitialized() public view returns (bool) {
        return _getInitializedVersion() > 0;
    }

    /**
     * @notice Get the storage pointer for this contract
     * @return store Storage struct pointer
     */
    function _getStorage() private pure returns (Storage storage store) {
        bytes32 position = STORAGE_LOCATION;
        assembly {
            store.slot := position
        }
    }

    /**
     * @notice Register a new document
     * @param _document The document to register
     * @param _controller The controller address
     */
    function registerDocument(
        DocumentLibrary.Document calldata _document,
        address _controller
    ) external onlyOpenDID returns (bool) {
        Storage storage store = _getStorage();

        require(_controller != address(0), "DocumentStorage: Controller cannot be zero address");

        // Store the document with its ID
        store._doc[_document.id] = _document;

        // Store version-specific document
        string memory versionedId = _getVersionedId(
            _document.id,
            _document.versionId
        );
        store._doc[versionedId] = _document;

        // Initialize document status
        store._docStatus[_document.id] = DocumentLibrary.DocumentStatus({
            id: _document.id,
            status: DocumentLibrary.DIDDOC_STATUS.ACTIVATED,
            version: _document.versionId,
            roleType: "",
            terminatedTime: ""
        });

        // Track document ownership
        store._documentIds[_controller].push(_document.id);

        emit DocumentRegistered(_document.id, _controller);
        return true;
    }

    /**
     * @notice Get a document by ID
     * @param _did The document ID
     * @return The document
     */
    function getDocument(
        string calldata _did
    ) external view returns (DocumentLibrary.DocumentAndStatus memory) {
        // Check if the document exists
        require(
            bytes(_did).length > 0,
            "DocumentStorage: Document ID cannot be empty"
        );

        // Return the document
        // Check if the document exists
        require(_isExistDocument(_did), "Document is not exist");
        DocumentLibrary.Document memory doc = _getStorage()._doc[_did];

        return
            DocumentLibrary.DocumentAndStatus(
                doc,
                _getStorage()._docStatus[_did].status
            );
    }

    /**
     * @notice Get a specific version of a document
     * @param _did The document ID
     * @param _versionId The version ID
     * @return The document
     */
    function getDocument(
        string calldata _did,
        string calldata _versionId
    ) external view returns (DocumentLibrary.Document memory) {
        // Check param _did The document ID
        require(
            bytes(_did).length > 0,
            "DocumentStorage: Document ID cannot be empty"
        );

        Storage storage store = _getStorage();

        if (bytes(_versionId).length == 0) {
            return store._doc[_did];
        }

        return store._doc[_getVersionedId(_did, _versionId)];
    }

    function _isExistDocument(
        string calldata _did
    ) internal view returns (bool) {
        Storage storage store = _getStorage();
        // Check if the document exists
        return bytes(store._doc[_did].id).length > 0;
    }

    /**
     * @notice Get a document's status
     * @param _did The document ID
     * @return The document status
     */
    function getDocumentStatus(
        string calldata _did
    ) external view returns (DocumentLibrary.DocumentStatus memory) {
        require(
            bytes(_did).length > 0,
            "DocumentStorage: Document ID cannot be empty"
        );
        require(_isExistDocumentStatus(_did), "Document status is not exist");

        return _getStorage()._docStatus[_did];
    }

    function _isExistDocumentStatus(
        string calldata _did
    ) internal view returns (bool) {
        Storage storage store = _getStorage();
        // Check if the document status exists
        return bytes(store._docStatus[_did].id).length > 0;
    }

    /**
     * @notice Get all documents owned by a controller
     * @param _controller The controller address
     * @return Array of document IDs
     */
    function getDocumentsByController(
        address _controller
    ) external view returns (string[] memory) {
        return _getStorage()._documentIds[_controller];
    }

    /**
     * @notice Update a document
     * @param _updatedDocument The updated document
     * @param _did The document ID
     * @param _versionId The version ID
     */
    function updateDocument(
        DocumentLibrary.Document calldata _updatedDocument,
        string calldata _did,
        string calldata _versionId
    ) external onlyOpenDID {
        Storage storage store = _getStorage();

        // Get latest document
        DocumentLibrary.Document memory latestDocument = store._doc[_did];

        // Compare versions
        uint256 latestVersion = StringUtils.stringToUint(
            latestDocument.versionId
        );
        uint256 updatedVersion = StringUtils.stringToUint(
            _updatedDocument.versionId
        );

        // Update main document reference if version is newer or equal
        if (latestVersion <= updatedVersion) {
            store._doc[_did] = _updatedDocument;
        }

        // Always store version-specific document
        store._doc[_getVersionedId(_did, _versionId)] = _updatedDocument;

        emit DocumentUpdated(_did, _versionId);
    }

    /**
     * @notice Remove a document
     * @param _did The document ID
     */
    function removeDocument(string calldata _did) external onlyOpenDID {
        Storage storage store = _getStorage();
        delete store._doc[_did];
        emit DocumentRemoved(_did);
    }

    /**
     * @notice Update a document's status
     * @param _documentStatus The new document status
     * @param _did The document ID
     */
    function updateDocumentStatus(
        DocumentLibrary.DocumentStatus calldata _documentStatus,
        string calldata _did
    ) external onlyOpenDID {
        Storage storage store = _getStorage();
        store._docStatus[_did] = _documentStatus;
        emit DocumentStatusUpdated(_did, _documentStatus.status);
    }

    /**
     * @notice Helper function to create versioned document ID
     * @param _did The document ID
     * @param _versionId The version ID
     * @return Versioned document ID
     */
    function _getVersionedId(
        string memory _did,
        string memory _versionId
    ) private pure returns (string memory) {
        return string(abi.encodePacked(_did, _versionId));
    }
}
