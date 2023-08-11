'use client';

import { Button } from './Button';
import {
  useSetupAP721,
  useSetLogic,
  useSetRenderer,
  useStore,
  useOverwrite,
} from '@public-assembly/ap-hooks';
import { Hash, Hex, encodeAbiParameters, parseAbiParameters } from 'viem';
import { useAccount } from 'wagmi';
import { Debug, Grid } from './base';
import { DescriptiveButton } from './DescriptiveButton';
import { OpenInNewWindowIcon, Pencil2Icon } from '@radix-ui/react-icons';

const databaseImpl: Hex = '0xFE16d7a18A1c00e8f07Ca11A1d29e69A69d67d7b';
const factoryImpl: Hex = '0x506615B90099d2d7031B34f455A5803F5Cae68Cb';
const logicImpl: Hex = '0x9c9FA39424F755F2a82eE01cb6a91212F300f55d';
const rendererImpl: Hex = '0x92964176f59080c5785fAAB8318B32638ec37970';
const emptyInit: Hex = '0x';
const existingAP721: Hex = '0x2F2882485D87D21230e9369ED73aDdbE4671c0BF';

type ButtonGridProps = {
  className?: string;
};

export const ButtonGrid = ({ className }: ButtonGridProps) => {
  // const { address, isConnected } = useAccount();

  // /* SetupAP721 Hook */
  // const databaseInitInput: Hash = encodeAbiParameters(
  //   parseAbiParameters('address, address, bool, bytes, bytes'),
  //   [logicImpl, rendererImpl, false, emptyInit, emptyInit]
  // );

  // const factoryInitInput: Hash = encodeAbiParameters(
  //   parseAbiParameters('string, string'),
  //   ['AssemblyPress', 'AP'] // name + symbol
  // );

  // const { setupAP721, setupAP721Loading, setupAP721Success } = useSetupAP721({
  //   database: databaseImpl,
  //   databaseInit: databaseInitInput,
  //   initialOwner: address,
  //   factory: factoryImpl,
  //   factoryInit: factoryInitInput,
  //   prepareTxn: true
  // });

  // /* SetLogic Hook */
  // const { setLogic, setLogicLoading, setLogicSuccess } = useSetLogic({
  //   database: databaseImpl,
  //   target: existingAP721,
  //   logic: logicImpl,
  //   logicInit: emptyInit,
  // });

  // /* SetRenderer Hook */
  // const { setRenderer, setRendererLoading, setRendererSuccess } =
  //   useSetRenderer({
  //     database: databaseImpl,
  //     target: existingAP721,
  //     renderer: rendererImpl,
  //     rendererInit: emptyInit,
  //   });

  // /* Store Hook */
  // const encodedString: Hash = encodeAbiParameters(
  //   parseAbiParameters('string'),
  //   ['Lifeworld']
  // );

  // const encodedBytesArray: Hash = encodeAbiParameters(
  //   parseAbiParameters('bytes[]'),
  //   [[encodedString]]
  // );

  // const { store, storeLoading, storeSuccess } = useStore({
  //   database: databaseImpl,
  //   target: existingAP721,
  //   quantity: BigInt(1),
  //   data: encodedBytesArray,
  // });

  // /* Overwrite Hook */
  // const encodedString2: Hash = encodeAbiParameters(
  //   parseAbiParameters('string'),
  //   ['River']
  // );

  // const arrayOfBytes: Hash[] = [encodedString2];

  // const { overwrite, overwriteLoading, overwriteSuccess } = useOverwrite({
  //   database: databaseImpl,
  //   target: existingAP721,
  //   tokenIds: [BigInt(1)],
  //   data: arrayOfBytes,
  // });

  // return (
  //   <Grid className='grid-cols-2 gap-4'>
  //     <DescriptiveButton
  //       label={'setupAP721'}
  //       description={'Deploy + configure an ERC721 contract which represents a row in the database'}
  //       // icon={<OpenInNewWindowIcon className='text-picton-blue' />}
  //       icon={<Pencil2Icon className='text-picton-blue' />}
  //       callback={setupAP721}
  //       callbackLoading={setupAP721Loading}
  //     />
  //     <DescriptiveButton
  //       label={'store'}
  //       description={
  //         'Store generic data in the database and mint a storage receipt'
  //       }
  //       icon={<Pencil2Icon className='text-picton-blue' />}
  //       callback={store}
  //       callbackLoading={storeLoading}
  //     />
  //     <DescriptiveButton
  //       label={'overwrite'}
  //       description={
  //         'Overwrite data associated with existing token'
  //       }
  //       icon={<Pencil2Icon className='text-picton-blue' />}
  //       callback={overwrite}
  //       callbackLoading={overwriteLoading}
  //     />   
  //     <DescriptiveButton
  //       label={'setLogic'}
  //       description={
  //         'Update logic contract associated with given row'
  //       }
  //       icon={<Pencil2Icon className='text-picton-blue' />}
  //       callback={setLogic}
  //       callbackLoading={setLogicLoading}
  //     />              
  //     <DescriptiveButton
  //       label={'setRenderer'}
  //       description={
  //         'Update renderer contract associated with given row'
  //       }
  //       icon={<Pencil2Icon className='text-picton-blue' />}
  //       callback={setRenderer}
  //       callbackLoading={setRendererLoading}
  //     />          
  //   </Grid>
  // );
};
