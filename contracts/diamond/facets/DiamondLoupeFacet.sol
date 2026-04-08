// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondLoupeFacet is IDiamondLoupe {
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        address[] memory seenFacets = new address[](selectorCount);
        uint256 facetCount;

        for (uint256 i; i < selectorCount; i++) {
            address facetAddr = ds.selectorToFacetAndPosition[ds.selectors[i]].facetAddress;
            bool exists;
            for (uint256 j; j < facetCount; j++) {
                if (seenFacets[j] == facetAddr) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                seenFacets[facetCount] = facetAddr;
                facetCount++;
            }
        }

        facets_ = new Facet[](facetCount);
        for (uint256 i; i < facetCount; i++) {
            address facetAddr = seenFacets[i];
            uint256 count;
            for (uint256 j; j < selectorCount; j++) {
                if (ds.selectorToFacetAndPosition[ds.selectors[j]].facetAddress == facetAddr) {
                    count++;
                }
            }

            bytes4[] memory selectors = new bytes4[](count);
            uint256 idx;
            for (uint256 j; j < selectorCount; j++) {
                bytes4 selector = ds.selectors[j];
                if (ds.selectorToFacetAndPosition[selector].facetAddress == facetAddr) {
                    selectors[idx] = selector;
                    idx++;
                }
            }

            facets_[i] = Facet({ facetAddress: facetAddr, functionSelectors: selectors });
        }
    }

    function facetFunctionSelectors(
        address _facet
    ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 count;

        for (uint256 i; i < selectorCount; i++) {
            if (ds.selectorToFacetAndPosition[ds.selectors[i]].facetAddress == _facet) {
                count++;
            }
        }

        facetFunctionSelectors_ = new bytes4[](count);
        uint256 idx;
        for (uint256 i; i < selectorCount; i++) {
            bytes4 selector = ds.selectors[i];
            if (ds.selectorToFacetAndPosition[selector].facetAddress == _facet) {
                facetFunctionSelectors_[idx] = selector;
                idx++;
            }
        }
    }

    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        address[] memory seenFacets = new address[](selectorCount);
        uint256 facetCount;

        for (uint256 i; i < selectorCount; i++) {
            address facetAddr = ds.selectorToFacetAndPosition[ds.selectors[i]].facetAddress;
            bool exists;
            for (uint256 j; j < facetCount; j++) {
                if (seenFacets[j] == facetAddr) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                seenFacets[facetCount] = facetAddr;
                facetCount++;
            }
        }

        facetAddresses_ = new address[](facetCount);
        for (uint256 i; i < facetCount; i++) {
            facetAddresses_[i] = seenFacets[i];
        }
    }

    function facetAddress(
        bytes4 _functionSelector
    ) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }
}
