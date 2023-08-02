import { Hex } from 'viem';
import { AP721DatabaseV1Abi } from '../abi';
import { EventObject } from '../types';

export const databaseEventsArray = [
  'SetupAP721',
  'DataStored',
  'DataOverwritten',
  'DataRemoved',
  'LogicUpdated',
  'RendererUpdated',
];

export const databaseEvents = {
  DATA_OVERWRITTEN: 'DataOverwritten',
  DATA_REMOVED: 'DataRemoved',
  DATA_STORED: 'DataStored',
  LOGIC_UPDATED: 'LogicUpdated',
  RENDERER_UPDATED: 'RendererUpdated',
  SETUP_AP721: 'SetupAP721',
};

export const databaseEventObjects: EventObject[] = [
  {
    event: databaseEvents.DATA_OVERWRITTEN,
    abi: AP721DatabaseV1Abi,
    address: process.env.DATABASE_CONTRACT as Hex,
  },
  {
    event: databaseEvents.DATA_REMOVED,
    abi: AP721DatabaseV1Abi,
    address: process.env.DATABASE_CONTRACT as Hex,
  },
  {
    event: databaseEvents.DATA_STORED,
    abi: AP721DatabaseV1Abi,
    address: process.env.DATABASE_CONTRACT as Hex,
  },
  {
    event: databaseEvents.LOGIC_UPDATED,
    abi: AP721DatabaseV1Abi,
    address: process.env.DATABASE_CONTRACT as Hex,
  },
  {
    event: databaseEvents.RENDERER_UPDATED,
    abi: AP721DatabaseV1Abi,
    address: process.env.DATABASE_CONTRACT as Hex,
  },
  {
    event: databaseEvents.SETUP_AP721,
    abi: AP721DatabaseV1Abi,
    address: process.env.DATABASE_CONTRACT as Hex,
  },
];
