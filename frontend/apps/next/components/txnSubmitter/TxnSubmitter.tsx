'use client';

import { useFunctionSelect } from 'context/FunctionSelectProvider';
import { Flex, CaptionLarge, BodySmall, BodyExtraSmall } from '../base';
import {
  useSetupAP721,
  useSetLogic,
  useSetRenderer,
  useStore,
  useOverwrite,
} from '@public-assembly/ap-hooks';
import { useAccount } from 'wagmi';
import { Hash, encodeAbiParameters, parseAbiParameters } from 'viem';
import { Button } from '../Button';
import { ArrowRightIcon } from '@radix-ui/react-icons';
import { shortenAddress } from '@/utils/shortenAddress';
import {
  databaseImpl,
  logicImpl,
  rendererImpl,
  emptyInit,
  factoryImpl,
  existingAP721,
} from 'app/constants';

export const TxnSubmitter = () => {
  // Get current selector from global context
  const { selector } = useFunctionSelect();
  // Get address of current authd user
  const { address } = useAccount();
  // Get prepareTxn value for hooks
  const user = address ? true : false;

  // function for determining what message to show for `from`
  const fromText = () => {
    if (user) {
      return shortenAddress(address);
    } else {
      return 'n/a';
    }
  };

  /* SetupAP721 Hook */
  const databaseInitInput: Hash = encodeAbiParameters(
    parseAbiParameters('address, address, bool, bytes, bytes'),
    [logicImpl, rendererImpl, false, emptyInit, emptyInit]
  );

  const factoryInitInput: Hash = encodeAbiParameters(
    parseAbiParameters('string, string'),
    ['AssemblyPress', 'AP'] // name + symbol
  );

  const { setupAP721Config, setupAP721, setupAP721Loading, setupAP721Success } =
    useSetupAP721({
      database: databaseImpl,
      databaseInit: databaseInitInput,
      initialOwner: address,
      factory: factoryImpl,
      factoryInit: factoryInitInput,
      prepareTxn: user,
    });

  /* SetLogic Hook */
  const { setLogicConfig, setLogic, setLogicLoading, setLogicSuccess } =
    useSetLogic({
      database: databaseImpl,
      target: existingAP721,
      logic: logicImpl,
      logicInit: emptyInit,
      prepareTxn: user,
    });

  /* SetRenderer Hook */
  const {
    setRendererConfig,
    setRenderer,
    setRendererLoading,
    setRendererSuccess,
  } = useSetRenderer({
    database: databaseImpl,
    target: existingAP721,
    renderer: rendererImpl,
    rendererInit: emptyInit,
    prepareTxn: user,
  });

  /* Store Hook */
  const encodedString: Hash = encodeAbiParameters(
    parseAbiParameters('string'),
    ['Lifeworld']
  );

  const encodedBytesArray: Hash = encodeAbiParameters(
    parseAbiParameters('bytes[]'),
    [[encodedString]]
  );

  const { storeConfig, store, storeLoading, storeSuccess } = useStore({
    database: databaseImpl,
    target: existingAP721,
    quantity: BigInt(1),
    data: encodedBytesArray,
    prepareTxn: user,
  });

  /* Overwrite Hook */
  const encodedString2: Hash = encodeAbiParameters(
    parseAbiParameters('string'),
    ['River']
  );

  const arrayOfBytes: Hash[] = [encodedString2];

  const { overwriteConfig, overwrite, overwriteLoading, overwriteSuccess } =
    useOverwrite({
      database: databaseImpl,
      target: existingAP721,
      tokenIds: [BigInt(1)],
      data: arrayOfBytes,
      prepareTxn: user,
    });

  const handleTxn = () => {
    switch (selector) {
      case 0:
        console.log('running setupAP721');
        setupAP721?.();
        break;
      case 1:
        console.log('running setLogic');
        setLogic?.();
        break;
      case 2:
        console.log('running setRenderer');
        setRenderer?.();
        break;
      case 3:
        console.log('running store');
        store?.();
        break;
      case 4:
        console.log('running overwrite');
        overwrite?.();
        break;
    }
  };

  const functionConfigMap = {
    0: setupAP721Config,
    1: setLogicConfig,
    2: setRendererConfig,
    3: storeConfig,
    4: overwriteConfig,
  };

  // function for determing what message to show for `from`
  const argsText = () => {
    if (functionConfigMap?.[selector]?.request?.args) {
      return functionConfigMap?.[selector]?.request?.args.join(',\n');
    } else {
      return 'Connect your wallet to see these arguments';
    }
  };

  // Map selector values to corresponding snippets
  // const functionNameMap = {
  //   0: 'setupAP721',
  //   1: 'setLogic',
  //   2: 'setRenderer',
  //   3: 'store',
  //   4: 'overwrite',
  // };

  // const functionLoadingMap = {
  //     0: setupAP721Loading,
  //     1: setLogicLoading,
  //     2: setRendererLoading,
  //     3: storeLoading,
  //     4: overwriteLoading
  // };

  // const activeFunctionLoading = () => {
  //     console.log("selector: ", selector)
  //     console.log("loading?: ", functionLoadingMap?.[selector])
  //     return functionLoadingMap?.[selector]
  // }

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
        <a
          href={`https://goerli-optimism.etherscan.io/address/${databaseImpl}`}
        >
          <Flex className='hover:border-dark-gray  px-2 py-[2px] bg-dark-gunmetal rounded-[18px] border border-arsenic justify-center items-center w-fit'>
            {/* To:&nbsp; */}
            <BodySmall className='text-dark-gray'>
              {shortenAddress(databaseImpl)}
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
