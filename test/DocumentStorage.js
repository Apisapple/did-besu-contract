const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { getLocalJson } = require("./Utils");

describe("DocumentStorage", function () {

    // Contracts are deployed using the first signer/account by default
    async function deployDocumentStorage() {
        const [owner, otherAccount] = await ethers.getSigners();

        const DocumentStorage = await ethers.getContractFactory("DocumentStorage");
        const documentStorage = await DocumentStorage.deploy();
        await documentStorage.setOpenDIDAddress(owner.address);

        return { documentStorage, owner, otherAccount };
    }

    describe("Deployment", function () {
        it("Should emit DocumentStorageSetup event on initialization", async function () {
            const { documentStorage } = await loadFixture(deployDocumentStorage);
            // Check if the contract is already initialized
            const isInitialized = await documentStorage.hasInitialized();
            if (!isInitialized) {
                await expect(documentStorage.initialize())
                    .to.emit(documentStorage, "DocumentStorageSetup");
            }
        });
    });

    describe("Document Management", function () {
        it("Should register and retrieve a document", async function () {
            const { documentStorage, owner } = await loadFixture(deployDocumentStorage);
            const document = getLocalJson("./data/document.json");

            await documentStorage.registerDocument(document, owner.address);
            const storedDocument = await documentStorage.getDocument(document.id);

            expect(storedDocument.diddoc.controller).to.equal(document.controller);
            expect(storedDocument.status).to.equal(0);  // ACTIVE status
        });

        it("Should update a document", async function () {
            const { documentStorage, owner } = await loadFixture(deployDocumentStorage);
            const document = getLocalJson("./data/document.json");

            await documentStorage.registerDocument(document, owner.address);

            const updatedDocument = { ...document, versionId: "2" };
            await documentStorage.updateDocument(updatedDocument, document.id, "2");

            const storedDocument = await documentStorage.getDocument(document.id);
            expect(storedDocument.diddoc.versionId).to.equal("2");
        });

        it("Should update document status", async function () {
            const { documentStorage, owner } = await loadFixture(deployDocumentStorage);
            const document = getLocalJson("./data/document.json");

            await documentStorage.registerDocument(document, owner.address);

            const newStatus = {
                id: document.id,
                status: 1, // DEACTIVATED
                version: document.versionId,
                roleType: "admin",
                terminatedTime: "2025-04-08T00:00:00Z",
            };

            await documentStorage.updateDocumentStatus(newStatus, document.id);

            const storedStatus = await documentStorage.getDocumentStatus(document.id);
            expect(storedStatus.status).to.equal(1); // DEACTIVATED
            expect(storedStatus.terminatedTime).to.equal("2025-04-08T00:00:00Z");
        });

        it("Should remove a document", async function () {
            const { documentStorage, owner } = await loadFixture(deployDocumentStorage);
            const document = getLocalJson("./data/document.json");

            await documentStorage.registerDocument(document, owner.address);
            await documentStorage.removeDocument(document.id);

            expect(
                documentStorage.getDocument(document.id)
            ).to.be.revertedWith("Document does not exist");
        });

        it("Should revert when getting a non-existent document", async function () {
            const { documentStorage } = await loadFixture(deployDocumentStorage);
            await expect(
                documentStorage.getDocument("non-existent-id")
            ).to.be.reverted;
        });

        it("Should emit events on register, update, and remove", async function () {
            const { documentStorage, owner } = await loadFixture(deployDocumentStorage);
            const document = getLocalJson("./data/document.json");
            await expect(documentStorage.registerDocument(document, owner.address))
                .to.emit(documentStorage, "DocumentRegistered");
            const updatedDocument = { ...document, versionId: "2" };
            await expect(documentStorage.updateDocument(updatedDocument, document.id, "2"))
                .to.emit(documentStorage, "DocumentUpdated");
            await expect(documentStorage.removeDocument(document.id))
                .to.emit(documentStorage, "DocumentRemoved");
        });
    });
});