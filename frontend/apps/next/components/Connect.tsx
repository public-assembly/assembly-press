import { ConnectKitButton } from 'connectkit';

export const Connect = () => {
  return (
    <ConnectKitButton.Custom>
      {({ isConnected, show, truncatedAddress, ensName }) => {
        return (
          <button
            type='button'
            className='px-4 py-3 bg-dark-gunmetal rounded-xl border border-arsenic justify-center items-center flex text-platinum hover:border-dark-gray'
            onClick={show}
          >
            {isConnected ? ensName ?? truncatedAddress : 'Connect Wallet'}
          </button>
        );
      }}
    </ConnectKitButton.Custom>
  );
};
