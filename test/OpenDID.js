const { expect } = require("chai");
const { ethers } = require("hardhat");
const { getLocalJson } = require("./Utils");

function getSelectors(contract) {
  return contract.interface.fragments
    .filter((f) => f.type === "function")
    .map((f) => contract.interface.getFunction(f.name).selector);
}

function uniqueAbi(contracts) {
  const abi = [];
  const seen = new Set();

  for (const contract of contracts) {
    for (const fragment of contract.interface.fragments) {
      if (fragment.type === "function" || fragment.type === "event") {
        const key = fragment.format("full");
        if (!seen.has(key)) {
          seen.add(key);
          abi.push(fragment);
        }
      }
    }
  }

  return abi;
}

describe("OpenDID Contract", function () {
  this.timeout(50000);

  let openDID, owner, addr1, diamondAddress;

  beforeEach(async () => {
    [owner, addr1] = await ethers.getSigners();

    const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
    const diamondCutFacet = await DiamondCutFacet.deploy();
    await diamondCutFacet.waitForDeployment();

    const Diamond = await ethers.getContractFactory("Diamond");
    const diamond = await Diamond.deploy(owner.address, await diamondCutFacet.getAddress());
    await diamond.waitForDeployment();
    diamondAddress = await diamond.getAddress();

    const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);

    const facetNames = [
      "DiamondLoupeFacet",
      "OwnershipFacet",
      "OpenDIDAdminFacet",
      "OpenDIDDidDocFacet",
      "OpenDIDDidStatusFacet",
      "OpenDIDVcFacet",
      "OpenDIDZKPFacet",
    ];

    const cut = [];
    const deployedFacets = [];

    for (const facetName of facetNames) {
      const Facet = await ethers.getContractFactory(facetName);
      const facet = await Facet.deploy();
      await facet.waitForDeployment();
      deployedFacets.push(facet);

      cut.push({
        facetAddress: await facet.getAddress(),
        action: 0,
        functionSelectors: getSelectors(facet),
      });
    }

    const OpenDIDInit = await ethers.getContractFactory("OpenDIDInit");
    const openDIDInit = await OpenDIDInit.deploy();
    await openDIDInit.waitForDeployment();

    const initCalldata = openDIDInit.interface.encodeFunctionData("init", [
      owner.address,
    ]);

    const tx = await diamondCut.diamondCut(cut, await openDIDInit.getAddress(), initCalldata);
    await tx.wait();

    const mergedAbi = uniqueAbi(deployedFacets);
    openDID = new ethers.Contract(diamondAddress, mergedAbi, owner);
  });

  it("should initialize the OpenDID contract", async () => {
    expect(await openDID.hasInitialized()).to.be.true;
  });

  it("should register Admin role to addr1", async () => {
    await openDID.registRole(addr1.address, "Admin");
    expect(await openDID.isHaveRole(addr1.address, "Admin")).to.be.true;
  });

  it("should register a base58 encoding did document with addr1 (TAS role)", async () => {
    const didDoc = getLocalJson("./data/tas_base58_verificationMethod.json");
    // owner가 addr1에게 TAS 역할 부여
    await openDID.registRole(addr1.address, "Tas");
    // addr1로 등록
    await expect(openDID.connect(addr1).registDidDoc(didDoc))
      .to.emit(openDID, "DIDCreated")
      .withArgs(didDoc.id, addr1.address);
    const storedDocumentAndStatus = await openDID.getDidDoc(didDoc.id);
    expect(storedDocumentAndStatus.diddoc.id).to.equal(didDoc.id);
    expect(storedDocumentAndStatus.status).to.equal(0);
  });

  it("should register a base64 encoding did document with owner (TAS role)", async () => {
    const didDoc = getLocalJson("./data/tas_base64_verificationMethod.json");
    await openDID.registRole(owner.address, "Tas");
    await expect(openDID.connect(owner).registDidDoc(didDoc))
      .to.emit(openDID, "DIDCreated")
      .withArgs(didDoc.id, owner.address);
    const storedDocumentAndStatus = await openDID.getDidDoc(didDoc.id);
    expect(storedDocumentAndStatus.diddoc.id).to.equal(didDoc.id);
    expect(storedDocumentAndStatus.status).to.equal(0);
  });

  it("should not search for a non-existent DID document", async () => {
    await expect(openDID.getDidDoc("nonExistentDidDocId")).to.be.revertedWith("Document is not exist");
  });

  it("should update the status of a DID document in service", async () => {
    const didDoc = getLocalJson("./data/document.json");
    await openDID.registRole(owner.address, "Tas");
    await openDID.connect(owner).registDidDoc(didDoc);
    const newStatus = "DEACTIVATED";
    const versionId = didDoc.versionId;
    await openDID.updateDidDocStatusInService(didDoc.id, newStatus, versionId);
    const updatedDidDoc = await openDID.getDidDoc(didDoc.id);
    expect(updatedDidDoc.diddoc.deactivated).to.equal(true);
  });

  it("should update the status of a DID document with revocation", async () => {
    const didDoc = getLocalJson("./data/document.json");
    await openDID.registRole(owner.address, "Tas");
    await openDID.connect(owner).registDidDoc(didDoc);
    const newStatus = "TERMINATED";
    const terminatedTime = "2025-04-08T00:00:00Z";
    await openDID.updateDidDocStatusRevocation(didDoc.id, newStatus, terminatedTime);
    const storedStatus = await openDID.getDidDocStatus(didDoc.id);
    expect(storedStatus.status).to.equal(3);
    expect(storedStatus.terminatedTime).to.equal(terminatedTime);
  });

  it("should register and retrieve VC metadata", async () => {
    const vcMeta = getLocalJson("./data/vcmeta.json");

    // addr1을 issuer로 사용
    await openDID.registRole(addr1.address, "Issuer");

    await expect(openDID.connect(addr1).registVcMetaData(vcMeta))
      .to.emit(openDID, "VCIssued")
      .withArgs(vcMeta.id, addr1.address, vcMeta.issuer.did);
    const storedVcMeta = await openDID.getVcmetaData(vcMeta.id);
    expect(storedVcMeta.id).to.equal(vcMeta.id);
    expect(storedVcMeta.issuer.did).to.equal(vcMeta.issuer.did);
    expect(storedVcMeta.issuanceDate).to.equal(vcMeta.issuanceDate);
    expect(storedVcMeta.expirationDate).to.equal(vcMeta.expirationDate);
    expect(storedVcMeta.credentialSchema.url).to.equal(vcMeta.credentialSchema.url);
  });

  it("should register vc schema data", async () => {
    const vcSchema = getLocalJson('./data/vc-schema.json');
    await openDID.registRole(addr1.address, "Issuer");
    await expect(openDID.connect(addr1).registVcSchema(vcSchema))
      .to.emit(openDID, "VCSchemaCreated")
      .withArgs(vcSchema.id, addr1.address);

    const storedVcSchema = await openDID.getVcSchema(vcSchema.id);
    expect(storedVcSchema.id).to.equal(vcSchema.id);
    expect(storedVcSchema.schema).to.equal(vcSchema.schema);
  });

  it("should only allow ISSUER to register and get ZKP credential schema", async () => {
    // addr1에게 ISSUER 권한 부여
    await openDID.registRole(addr1.address, "Issuer");

    const credentialSchema = getLocalJson("./data/credential-schema.json");

    // 권한 없는 계정은 실패
    await expect(
      openDID.registZKPCredential(credentialSchema)
    ).to.be.revertedWith("Caller does not have Issuer role");

    // 권한 있는 계정은 성공
    await expect(
      openDID.connect(addr1).registZKPCredential(credentialSchema)
    ).to.not.be.reverted;

    // 조회도 정상 동작
    const stored = await openDID.getZKPCredential(credentialSchema.id);
    expect(stored.id).to.equal(credentialSchema.id);
    expect(stored.name).to.equal(credentialSchema.name);
  });

  it("should only allow ISSUER to register and get ZKP credential definition", async () => {
    await openDID.registRole(addr1.address, "Issuer");

    const credentialDefinition = getLocalJson("./data/credential-definition.json");

    await expect(
      openDID.registZKPCredentialDefinition(credentialDefinition)
    ).to.be.revertedWith("Caller does not have Issuer role");

    await expect(
      openDID.connect(addr1).registZKPCredentialDefinition(credentialDefinition)
    ).to.not.be.reverted;

    const stored = await openDID.getZKPCredentialDefinition(credentialDefinition.id);
    expect(stored.id).to.equal(credentialDefinition.id);
    expect(stored.schemaId).to.equal(credentialDefinition.schemaId);
  });

  it("should revert registRole if target is zero address or roleType is empty", async () => {
    await expect(
      openDID.registRole(ethers.ZeroAddress, "ISSUER")
    ).to.be.revertedWith("Target address cannot be zero");

    await expect(
      openDID.registRole(addr1.address, "")
    ).to.be.revertedWith("Role type cannot be empty");
  });

  it("should revert isHaveRole if target is zero address or roleType is empty", async () => {
    await expect(
      openDID.isHaveRole(ethers.ZeroAddress, "ISSUER")
    ).to.be.revertedWith("Target address cannot be zero");

    await expect(
      openDID.isHaveRole(addr1.address, "")
    ).to.be.revertedWith("Role type cannot be empty");
  });

  it("should expose diamond owner", async () => {
    const ownership = await ethers.getContractAt("OwnershipFacet", diamondAddress);
    expect(await ownership.owner()).to.equal(owner.address);
  });
});
