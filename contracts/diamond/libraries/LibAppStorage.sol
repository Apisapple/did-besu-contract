// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../storage/DocumentStorage.sol";
import "../../storage/VcMetaStorage.sol";
import "../../storage/ZKPStorage.sol";
import "../../crypto/MultibaseContract.sol";

library LibAppStorage {
    bytes32 internal constant APP_STORAGE_POSITION =
        keccak256("opendid.diamond.app.storage");

    struct AppStorage {
        DocumentStorage documentStorage;
        VcMetaStorage vcMetaStorage;
        ZKPStorage zkpStorage;
        MultibaseContract multibaseContract;
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
