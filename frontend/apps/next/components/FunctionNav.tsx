'use client';

import { useFunctionSelect } from 'context/FunctionSelectProvider';
import { Flex, Grid, BodySmall } from './base';
import { Button } from './Button';

interface GridItemProps {
    functionName: string,
    selectorIndex: number
}

const GridItem = ({functionName, selectorIndex}: GridItemProps) => {

    const {selector, setSelector} = useFunctionSelect()
    return (
        <button onClick={() => setSelector(selectorIndex)}>
            <BodySmall className={selector === selectorIndex ? `text-white underline` : `hover:font-bold text-dark-gray`}>
                {functionName}
            </BodySmall>
        </button>
    )
}

export const FunctioNav = () => {

  return (
    <Grid className='grid-rows-1 grid-cols-5'>
        <GridItem functionName={'setupAP721'} selectorIndex={0} />
        <GridItem functionName={'setLogic'} selectorIndex={1} />
        <GridItem functionName={'setRenderer'} selectorIndex={2} />
        <GridItem functionName={'store'} selectorIndex={3} />
        <GridItem functionName={'overwrite'} selectorIndex={4} />
    </Grid>
  );
};
