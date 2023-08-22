'use client';

import { useFunctionSelect } from 'context/FunctionSelectProvider';
import { Flex, CaptionLarge, BodySmall, BodyExtraSmall } from './base';
import {
  useSetup,
  useStoreTokenData,
  useOverwriteTokenData,
  useUpdatePressData
} from '@public-assembly/ap-hooks';
import { useAccount } from 'wagmi';
import {
  Hash,
  Hex,
  encodeAbiParameters,
  parseAbiParameters,
  zeroAddress,
} from 'viem';
import { Button } from './Button';
import { ArrowRightIcon } from '@radix-ui/react-icons';
import { shortenAddress } from '@/utils/shortenAddress';
import { useModal } from 'connectkit';
import {
  router,
  logicImpl,
  rendererImpl,
  emptyInit,
  factoryImpl,
  deployedPress,
} from 'app/constants';

export const TxnSubmitter = () => {
  // Get current selector from global context
  const { selector } = useFunctionSelect();
  // Get address of current authd user
  const { address, isConnected } = useAccount();
  // Get prepareTxn value for hooks
  const user = address ? true : false;
  // Show/dismiss connectkit modal
  const { setOpen } = useModal();

  // function for determining what message to show for `from`
  const fromText = () => {
    if (user) {
      return shortenAddress(address);
    } else {
      return 'n/a';
    }
  };

  /* setup Hook */
  const factoryInit: Hash = encodeAbiParameters(
    parseAbiParameters(
      '(string, address, address, bytes, address, bytes, (address, uint16, bool, bool))'
    ),
    [
      [ // inner array necessary because we are encoding an Inputs struct that contains another struct (advancedSettings)
        'Public Assembly', // pressName
        address ? address : zeroAddress, // initialOwner
        logicImpl, // logic
        emptyInit, // logicInit
        rendererImpl, // renderer
        emptyInit, // rendererInit
        [zeroAddress, 0, false, false], // advancedSettings
    ]
  ]
  );

  const { setupConfig, setup, setupLoading, setupSuccess } = useSetup({
    factory: factoryImpl,
    factoryInit: factoryInit,
    prepareTxn: user,
  });

  /* storeTokenData Hook */
  const encodedString: Hash = encodeAbiParameters(
    parseAbiParameters('string'),
    ['Lifeworld']
  );

  const encodedBytesArray: Hash = encodeAbiParameters(
    parseAbiParameters('bytes[]'),
    [[encodedString]]
  );

  const {
    storeTokenDataConfig,
    storeTokenData,
    storeTokenDataLoading,
    storeTokenDataSuccess,
  } = useStoreTokenData({
    press: deployedPress,
    data: encodedBytesArray,
    prepareTxn: user,
  });

  /* overwriteTokenData Hook */
  const encodedOverwriteString: Hash = encodeAbiParameters(
    parseAbiParameters('string'),
    ['River']
  );

  const encodedOverwriteBytesArray: Hash = encodeAbiParameters(
    parseAbiParameters('bytes[]'),
    [[encodedOverwriteString]]
  );

  const tokenIdArray: bigint[] = [BigInt(1)]

  const encodedOverwriteData: Hash = encodeAbiParameters(
    parseAbiParameters('uint256[], bytes[]'),
    [tokenIdArray, [encodedOverwriteBytesArray]]
  )

  const {
    overwriteTokenDataConfig,
    overwriteTokenData,
    overwriteTokenDataLoading,
    overwriteTokenDataSuccess,
  } = useOverwriteTokenData({
    press: deployedPress,
    data: encodedOverwriteData,
    prepareTxn: user,
  });

  const {
    updatePressDataConfig,
    updatePressData,
    updatePressDataLoading,
    updatePressDataSuccess,
  } = useUpdatePressData({
    press: deployedPress,
    data: encodedBytesArray,
    prepareTxn: user,
  })

  const handleTxn = () => {
    if (!isConnected) {
      setOpen(true);
    }
    switch (selector) {
      case 0:
        console.log('running setup');
        setup?.();
        break;
      case 1:
        console.log('running storeTokenData');
        storeTokenData?.();
        break;
      case 2:
        console.log('running overwriteTokenData');
        overwriteTokenData?.();
        break;
      case 3:
        console.log('running updatePressData');
        updatePressData?.();
        break;
    }
  };

  const functionConfigMap = {
    0: setupConfig,
    1: storeTokenDataConfig,
    2: overwriteTokenDataConfig,
    3: updatePressDataConfig,
  };

  // function for determing what message to show for `from`
  const argsText = () => {
    if (functionConfigMap?.[selector]?.request?.args) {
      return functionConfigMap?.[selector]?.request?.args.join(',\n');
    } else {
      return 'Connect your wallet';
    }
  };

  return (
    <Flex className='flex-col justify-between p-4 gap-8 h-[432px]'>
      {/* From --> To */}
      <div className='flex flex-wrap justify-between items-center '>
        <a href={`https://goerli-optimism.etherscan.io/address/${address}`}>
          <Flex className='hover:border-dark-gray  px-2 py-[2px] bg-dark-gunmetal rounded-[18px] border border-arsenic justify-center items-center w-fit'>
            {/* From:&nbsp; */}
            <BodySmall className='text-dark-gray'>{fromText()}</BodySmall>
          </Flex>
        </a>
        <ArrowRightIcon />
        <a href={`https://goerli-optimism.etherscan.io/address/${router}`}>
          <Flex className='hover:border-dark-gray  px-2 py-[2px] bg-dark-gunmetal rounded-[18px] border border-arsenic justify-center items-center w-fit'>
            {/* To:&nbsp; */}
            <BodySmall className='text-dark-gray'>
              {shortenAddress(router)}
            </BodySmall>
          </Flex>
        </a>
      </div>
      {/* Args */}
      <div className='flex flex-wrap gap-y-2'>
        <BodySmall className='text-platinum'>Args:</BodySmall>
        <BodySmall className='border-white p-2 flex-col h-[180px] w-full bg-[#232528] text-dark-gray overflow-y-auto whitespace-pre-wrap break-all rounded'>
          {argsText()}
        </BodySmall>
      </div>
      {/* Submit */}
      <Button
        text={'Submit Transaction'}
        callback={handleTxn}
        callbackLoading={false}
      />
    </Flex>
  );
};
