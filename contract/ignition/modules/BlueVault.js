const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

/**
 * @notice Deployment module for the BlueVault smart contract.
 * @dev Uses Hardhat Ignition to deploy the BlueVault contract with predefined supported tokens.
 * @param {object} m - The module deployment object provided by Hardhat Ignition.
 * @return {object} An object containing the deployed BlueVault contract instance.
 */
module.exports = buildModule("BlueVaultModule", (m) => {
  const blueVault = m.contract("BlueVault");
  return { blueVault };
});
