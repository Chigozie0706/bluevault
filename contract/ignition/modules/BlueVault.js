const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

/**
 * @notice Deployment module for the DisasterManagement smart contract.
 * @dev Uses Hardhat Ignition to deploy the DisasterManagement contract with predefined supported tokens.
 * @param {object} m - The module deployment object provided by Hardhat Ignition.
 * @return {object} An object containing the deployed DisasterManagement contract instance.
 */
module.exports = buildModule("DisasterManagementModule", (m) => {
  const disasterManagement = m.contract("DisasterManagement");
  return { disasterManagement };
});
