import { AP721DatabaseV1Abi } from '../../abi/AP721DatabaseV1Abi'
import { AP721_DATABASE_V1 } from '../../constants'
import { EventObject } from '../../types'

export const eventNames = {
  DATA_OVERWRITTEN: 'DataOverwritten',
  DATA_REMOVED: 'DataRemoved',
  DATA_STORED: 'DataStored',
  LOGIC_UPDATED: 'LogicUpdated',
  RENDERER_UPDATED: 'RendererUpdated',
  SETUP_AP721: 'SetupAP721',
}

export const availableEventObjects: EventObject[] = [
  {
    event: eventNames.DATA_OVERWRITTEN,
    abi: AP721DatabaseV1Abi,
    address: AP721_DATABASE_V1.optimismGoerli,
  },
  {
    event: eventNames.DATA_REMOVED,
    abi: AP721DatabaseV1Abi,
    address: AP721_DATABASE_V1.optimismGoerli,
  },
  {
    event: eventNames.DATA_STORED,
    abi: AP721DatabaseV1Abi,
    address: AP721_DATABASE_V1.optimismGoerli,
  },
  {
    event: eventNames.LOGIC_UPDATED,
    abi: AP721DatabaseV1Abi,
    address: AP721_DATABASE_V1.optimismGoerli,
  },
  {
    event: eventNames.RENDERER_UPDATED,
    abi: AP721DatabaseV1Abi,
    address: AP721_DATABASE_V1.optimismGoerli,
  },
  {
    event: eventNames.SETUP_AP721,
    abi: AP721DatabaseV1Abi,
    address: AP721_DATABASE_V1.optimismGoerli,
  },
]
