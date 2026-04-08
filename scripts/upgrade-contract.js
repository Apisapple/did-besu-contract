const { ethers } = require("hardhat");

const DIAMOND_ADDRESS = process.env.DIAMOND_ADDRESS;

function getSelectors(contract) {
    return contract.interface.fragments
        .filter((f) => f.type === "function")
        .map((f) => contract.interface.getFunction(f.name).selector);
}

async function upgradeContract() {
    if (!DIAMOND_ADDRESS) {
        throw new Error("DIAMOND_ADDRESS environment variable is required");
    }

    const NewOpenDIDVcFacet = await ethers.getContractFactory("OpenDIDVcFacet");
    const newOpenDIDVcFacet = await NewOpenDIDVcFacet.deploy();
    await newOpenDIDVcFacet.waitForDeployment();

    const diamondCut = await ethers.getContractAt("IDiamondCut", DIAMOND_ADDRESS);

    const cut = [
        {
            facetAddress: await newOpenDIDVcFacet.getAddress(),
            action: 1,
            functionSelectors: getSelectors(newOpenDIDVcFacet),
        },
    ];

    const tx = await diamondCut.diamondCut(cut, ethers.ZeroAddress, "0x");
    await tx.wait();

    console.log("Facet replaced on diamond:", DIAMOND_ADDRESS);
}

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("Deploying the contract with the account:", await owner.getAddress());
    try {
        await upgradeContract();
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
    upgradeContract,
};
