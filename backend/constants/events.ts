import { DatabaseEvent } from '../types'

export const databaseEventsArray: DatabaseEvent[] = [
  'SetupAP721',
  'DataStored',
  'DataOverwritten',
  'DataRemoved',
  'LogicUpdated',
  'RendererUpdated',
]

export const databaseEventsObject = {
  DATA_OVERWRITTEN: 'DataOverwritten',
  DATA_REMOVED: 'DataRemoved',
  DATA_STORED: 'DataStored',
  LOGIC_UPDATED: 'LogicUpdated',
  RENDERER_UPDATED: 'RendererUpdated',
  SETUP_AP721: 'SetupAP721',
}
