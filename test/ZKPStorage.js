const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { getLocalJson } = require("./Utils");

describe("ZKPStorage", function () {
    // Contracts are deployed using the first signer/account by default
    async function deploy() {
        const [owner, otherAccount] = await ethers.getSigners();

        const ZKPStorage = await ethers.getContractFactory("ZKPStorage");
        const zkpStorage = await ZKPStorage.deploy();
        await zkpStorage.setOpenDIDAddress(owner.address);

        return { zkpStorage, owner, otherAccount };
    }


    describe("Deployment", function () {
        it("Should emit DocumentStorageSetup event on initialization", async function () {
            const { zkpStorage } = await loadFixture(deploy);
            // Check if the contract is already initialized
            const isInitialized = await zkpStorage.hasInitialized();
            if (!isInitialized) {
                await expect(zkpStorage.initialize())
                    .to.emit(zkpStorage, "ZKPStorageSetup");
            }
        });
    });

    describe("ZKPStorage", function () {
        it("Should store a schemas", async function () {
            const { zkpStorage, owner } = await loadFixture(deploy);
            const schema = getLocalJson("./data/credential-schema.json");

            await zkpStorage.registerSchema(schema);
            const storedSchemaValue = await zkpStorage.getSchema(schema.id);
            expect(storedSchemaValue.id).to.equal(schema.id);
        });

        it(
            "Should remove a schema",
            async function () {
                const { zkpStorage, owner } = await loadFixture(deploy);
                const schema = getLocalJson("./data/credential-schema.json");

                await zkpStorage.registerSchema(schema);
                await zkpStorage.removeSchema(schema.id);

                const storedSchemaValue = await zkpStorage.getSchema(schema.id);
                console.log("Stored schema value: ", storedSchemaValue);
                expect(storedSchemaValue.id).to.equal("");
            }
        );

        it("Should store a credential deifinition", async function () {
            const { zkpStorage, owner } = await loadFixture(deploy);
            const credentialDefinition = getLocalJson("./data/credential-definition.json");

            await zkpStorage.registerCredentialDefinition(credentialDefinition);
            const storedCredentialDefinitionValue = await zkpStorage.getCredentialDefinition(credentialDefinition.id);
            expect(storedCredentialDefinitionValue.id).to.equal(credentialDefinition.id);
        });

        it(
            "Should remove a credential definition",
            async function () {
                const { zkpStorage, owner } = await loadFixture(deploy);
                const credentialDefinition = getLocalJson("./data/credential-definition.json");

                await zkpStorage.registerCredentialDefinition(credentialDefinition);
                await zkpStorage.removeCredentialDefinition(credentialDefinition.id);

                const storedCredentialDefinitionValue = await zkpStorage.getCredentialDefinition(credentialDefinition.id);
                expect(storedCredentialDefinitionValue.id).to.equal("");
            }
        );
    });
});