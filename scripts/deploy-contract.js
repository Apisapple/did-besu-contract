const { ethers } = require("hardhat");

function getSelectors(contract) {
    return contract.interface.fragments
        .filter((f) => f.type === "function")
        .map((f) => contract.interface.getFunction(f.name).selector);
}

async function deployContract() {
    try {
        const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
        const diamondCutFacet = await DiamondCutFacet.deploy();
        await diamondCutFacet.waitForDeployment();

        const Diamond = await ethers.getContractFactory("Diamond");
        const [owner] = await ethers.getSigners();
        const diamond = await Diamond.deploy(
            owner.address,
            await diamondCutFacet.getAddress(),
        );
        await diamond.waitForDeployment();

        const diamondAddress = await diamond.getAddress();

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
        for (const facetName of facetNames) {
            const Facet = await ethers.getContractFactory(facetName);
            const facet = await Facet.deploy();
            await facet.waitForDeployment();

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

        console.log("OpenDID Diamond deployed to:", diamondAddress);

        return { diamond: diamondAddress };
    } catch (error) {
        console.error("Deployment failed:", error);
        throw error;
    }
}

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("Deploying the contract with the account:", await owner.getAddress());
    try {
        await deployContract();
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

main().then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

module.exports = {
    deployContract,
};
