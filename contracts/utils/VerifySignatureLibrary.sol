// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title VerifySignatureLibrary
 * @dev Utility library for verifying Ethereum signatures in Solidity.
 */
library VerifySignatureLibrary {
    /**
     * @dev Verifies that a signature is valid for a given message hash and signer address.
     * @param messageHash The hash of the original message.
     * @param signature The signature bytes.
     * @param signer The address expected to have signed the message.
     * @return True if the signature is valid, false otherwise.
     */
    function verifySignature(
        bytes32 messageHash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    /**
     * @dev Recovers the signer address from a signed message hash and signature.
     * @param ethSignedMessageHash The Ethereum signed message hash.
     * @param signature The signature bytes.
     * @return The recovered address.
     */
    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Splits a signature into r, s, v components.
     * @param sig The signature bytes (length 65).
     * @return r The r value.
     * @return s The s value.
     * @return v The v value.
     */
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        require(v == 27 || v == 28, "Invalid signature v value");

        uint256 sValue = uint256(s);
        require(
            sValue <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Invalid signature s value"
        );
    }
}
