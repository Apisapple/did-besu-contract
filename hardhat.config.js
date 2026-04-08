require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
const path = require("path");
const fs = require("fs");
const { task } = require("hardhat/config");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
    allowUnlimitedContractSize: true,
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    dev: {
      url: "http://10.48.17.200:50010",
      gasPrice: 0,
      blockGasLimit: 0x1fffffffffffff,
      gas: 2100000,
      accounts: [
        // "8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63",
        "1db336448e561fc74edc38a7d7e857bfa63664e8d4b37a3212fee7b5c36b66b8",
      ],
    },
  }
};

// 아티팩트 생성 유틸리티
function generateArtifactFiles(artifactPath) {
  const artifact = require(artifactPath);
  const contractName = path.basename(artifactPath, ".json");
  const outputDir = path.dirname(artifactPath);

  // ABI 파일 생성
  fs.writeFileSync(
    path.join(outputDir, `${contractName}.abi`),
    JSON.stringify(artifact.abi, null, 2)
  );

  // Bytecode 파일 생성
  fs.writeFileSync(
    path.join(outputDir, `${contractName}.bin`),
    artifact.bytecode.replace("0x", "")
  );
}

task("compile").setAction(async (_, { artifacts }, runSuper) => {
  await runSuper();
  const artifactPaths = await artifacts.getArtifactPaths();
  artifactPaths.forEach(generateArtifactFiles);
});
