export const updatePressDataSnippets = {
  // rome-ignore lint:
  typescript: `TODO`,
  solidity: `  function updatePressData(address press, bytes memory data) nonReentrant external payable {
        if (!pressRegistry[press]) revert Invalid_Press();
        (address pointer) = IPress(press).updatePressData{value: msg.value}(msg.sender, data);
        emit PressDataUpdated(msg.sender, press, pointer);
    }         `,
};
