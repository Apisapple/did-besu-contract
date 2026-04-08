// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint96 selectorPosition;
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndSelectorPosition) selectorToFacetAndPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }

        emit IDiamondCut.DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");

        uint96 selectorPosition = uint96(ds.selectors.length);
        enforceHasCode(_facetAddress, "LibDiamondCut: Add facet has no code");

        for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
            bytes4 selector = _selectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.selectorToFacetAndPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorPosition
            );
            ds.selectors.push(selector);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasCode(_facetAddress, "LibDiamondCut: Replace facet has no code");

        for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
            bytes4 selector = _selectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");

        for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
            bytes4 selector = _selectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacet = ds.selectorToFacetAndPosition[selector];
            require(oldFacet.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            require(oldFacet.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");

            uint256 lastSelectorPosition = ds.selectors.length - 1;
            bytes4 lastSelector = ds.selectors[lastSelectorPosition];

            if (uint256(oldFacet.selectorPosition) != lastSelectorPosition) {
                ds.selectors[oldFacet.selectorPosition] = lastSelector;
                ds.selectorToFacetAndPosition[lastSelector].selectorPosition = oldFacet.selectorPosition;
            }

            ds.selectors.pop();
            delete ds.selectorToFacetAndPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasCode(_init, "LibDiamondCut: _init address has no code");
            }

            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    revert(string(error));
                }
                revert("LibDiamondCut: _init function reverted");
            }
        }
    }

    function enforceHasCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
