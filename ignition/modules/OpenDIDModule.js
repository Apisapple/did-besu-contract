const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("OpenDIDModule", (m) => {
    const documentStorage = m.contract("DocumentStorage");
    const vcMetaStorage = m.contract("VcMetaStorage");
    const zkpStorage = m.contract("ZKPStorage");
    const multibaseContract = m.contract("MultibaseContract");

    const openDIDImplementation = m.contract("OpenDID");
    const initializeCallData = m.encodeFunctionCall(openDIDImplementation, "initialize", [
        documentStorage,
        vcMetaStorage,
        zkpStorage,
        multibaseContract,
    ]);

    const openDIDProxy = m.contract("OpenDIDProxy", [openDIDImplementation, initializeCallData]);
    const openDID = m.contractAt("OpenDID", openDIDProxy, { id: "OpenDIDProxyInstance" });

    return {
        documentStorage,
        vcMetaStorage,
        zkpStorage,
        multibaseContract,
        openDIDImplementation,
        openDIDProxy,
        openDID,
    };
});