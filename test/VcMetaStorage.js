const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { getLocalJson } = require("./Utils");
const { update } = require("lodash");

describe("VcMetaStorage", function () {
    // Contracts are deployed using the first signer/account by default
    async function deployVcMetaStorage() {
        const [owner, otherAccount] = await ethers.getSigners();

        const VcMetaStorage = await ethers.getContractFactory("VcMetaStorage");
        const vcMetaStorage = await VcMetaStorage.deploy();
        await vcMetaStorage.setOpenDIDAddress(owner.address);

        return { vcMetaStorage, owner, otherAccount };
    }


    describe("Deployment", function () {
        it("Should emit DocumentStorageSetup event on initialization", async function () {
            const { vcMetaStorage } = await loadFixture(deployVcMetaStorage);
            // Check if the contract is already initialized
            const isInitialized = await vcMetaStorage.hasInitialized();
            if (!isInitialized) {
                await expect(vcMetaStorage.initialize())
                    .to.emit(vcMetaStorage, "VcMetaStorageSetup");
            }
        });
    });

    describe("VcMetaStorage", function () {
        it("Should store a vcmeta", async function () {
            const { vcMetaStorage, owner } = await loadFixture(deployVcMetaStorage);
            const vcmeta = getLocalJson("./data/vcmeta.json");


            await expect(vcMetaStorage.registerVcMeta(vcmeta))
                .to.emit(vcMetaStorage, "VcMetaRegistered");

            await vcMetaStorage.registerVcMeta(vcmeta);
            const storedVcMeta = await vcMetaStorage.getVcMeta(vcmeta.id);

            expect(storedVcMeta.id).to.equal(vcmeta.id);
        });

        it("should update a vcmeta status", async function () {
            const { vcMetaStorage } = await loadFixture(deployVcMetaStorage);
            const vcmeta = getLocalJson("./data/vcmeta.json");

            await vcMetaStorage.registerVcMeta(vcmeta);
            const newStatus = "REVOKED";
            await vcMetaStorage.updateVcMetaStatus(vcmeta.id, newStatus);

            const updatedVcMeta = await vcMetaStorage.getVcMeta(vcmeta.id);
            expect(vcmeta.status).to.not.equal(updatedVcMeta.status);
            expect(newStatus).to.equal(updatedVcMeta.status);
        });
    });

    describe("VcSchemaMetaStorage", function () {
        it("Should register a vc schema meta", async function () {
            const { vcMetaStorage } = await loadFixture(deployVcMetaStorage);
            const vcSchema = getLocalJson("./data/vc-schema.json");

            await vcMetaStorage.registerVcSchema(vcSchema);
            const storedSchemaMeta = await vcMetaStorage.getVcSchema(vcSchema.id);
            expect(storedSchemaMeta.id).to.equal(vcSchema.id);
        });
    });
});