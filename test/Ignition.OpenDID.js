const { expect } = require("chai");
const { ethers, ignition } = require("hardhat");
const OpenDIDModule = require("../ignition/modules/OpenDIDModule");

describe("OpenDID Ignition Module", function () {
    this.timeout(60000);

    async function deployWithUniqueId() {
        return ignition.deploy(OpenDIDModule, {
            deploymentId: `opendid-module-${Date.now()}-${Math.floor(Math.random() * 100000)}`,
        });
    }

    it("should deploy and initialize OpenDID proxy", async () => {
        const { openDID } = await deployWithUniqueId();
        const [deployer] = await ethers.getSigners();
        const adminRole = ethers.keccak256(ethers.toUtf8Bytes("ADMIN_ROLE"));

        expect(await openDID.hasInitialized()).to.equal(true);
        expect(await openDID.hasRole(adminRole, await deployer.getAddress())).to.equal(true);
    });

    it("should allow role registration after ignition deployment", async () => {
        const { openDID } = await deployWithUniqueId();
        const [, addr1] = await ethers.getSigners();

        await openDID.registRole(addr1.address, "Tas");
        expect(await openDID.isHaveRole(addr1.address, "Tas")).to.equal(true);
    });
});